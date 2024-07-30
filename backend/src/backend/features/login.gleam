import backend/middleware/rate_limiting
import backend/middleware/view_context
import backend/models/user
import backend/models/user_session
import backend/types/email
import backend/types/password
import backend/types/username
import backend/web/context.{type AppContext, type RequestContext}
import formal/form
import gleam/bool
import gleam/erlang/process
import gleam/http.{Get, Post}
import gleam/int
import gleam/io
import gleam/option.{None, Some}
import gleam/pgo
import gleam/result
import shared/views/login
import wisp.{type Request, type Response}

pub fn login_handler(req: Request, app_ctx: AppContext, req_ctx: RequestContext) {
  case req.method {
    Get -> login_form(req_ctx)
    Post -> submit_login_form(req, app_ctx, req_ctx)
    _ -> wisp.method_not_allowed([Get, Post])
  }
}

pub fn login_form(req_ctx: RequestContext) {
  use <- bool.lazy_guard(option.is_some(req_ctx.user), fn() {
    wisp.redirect("/")
  })

  let view_ctx = view_context.get("Login", req_ctx)
  let form = form.new()

  login.login_page(view_ctx, form, None)
  |> wisp.html_response(200)
}

type LoginSubmissionType {
  EmailLoginSubmission(email_address: email.EmailAddress)
  UsernameLoginSubmission(username: username.Username)
}

fn parse_login_submission_type(
  input: String,
) -> Result(LoginSubmissionType, String) {
  case email.parse(input) {
    Ok(email_address) -> {
      Ok(EmailLoginSubmission(email_address))
    }
    _ -> {
      case username.parse(input) {
        Ok(username) -> Ok(UsernameLoginSubmission(username))
        _ -> Error("Username or email address format incorrect")
      }
    }
  }
}

type LoginSubmission {
  LoginSubmission(type_: LoginSubmissionType, password: password.Password)
}

type LoginError {
  InvalidCredentials
  UnknownLoginError
}

fn login(
  conn: pgo.Connection,
  submission: LoginSubmission,
) -> Result(#(user_session.SessionKey, Int), LoginError) {
  use user <- result.try({
    case submission.type_ {
      EmailLoginSubmission(email_address) -> {
        case user.get_by_email(conn, email_address) {
          Ok(user) -> Ok(user)
          Error(e) -> {
            io.debug(e)
            Error(UnknownLoginError)
          }
        }
      }
      UsernameLoginSubmission(username) -> {
        case user.get_by_username(conn, username) {
          Ok(user) -> Ok(user)
          Error(e) -> {
            io.debug(e)
            Error(UnknownLoginError)
          }
        }
      }
    }
  })

  use <- bool.lazy_guard(option.is_none(user), fn() {
    // Always perform a hashing comparison,
    // even when no user found,
    // to prevent timing attacks
    password.verify_random()
    Error(InvalidCredentials)
  })

  let assert Some(user) = user

  use <- bool.guard(
    !password.valid(submission.password, user.password_hash),
    Error(InvalidCredentials),
  )

  //   use <- bool.guard(user.disabled_or_locked(user), Error(InvalidCredentials))

  use session <- result.try({
    case user_session.create_with_defaults(conn, user.id) {
      Ok(session) -> Ok(session)
      Error(e) -> {
        io.debug(e)
        Error(UnknownLoginError)
      }
    }
  })

  Ok(session)
}

const login_submission_rate_window = 300_000

const login_ip_rate_limit = 10

fn submit_login_form(
  req: Request,
  app_ctx: AppContext,
  req_ctx: RequestContext,
) -> Response {
  use <- rate_limiting.rate_limit_by_ip(
    req,
    app_ctx,
    ["login", "submit"],
    login_submission_rate_window,
    login_ip_rate_limit,
  )

  let view_ctx = view_context.get("Login", req_ctx)
  use formdata <- wisp.require_form(req)

  let result =
    form.decoding({
      use submission_type <- form.parameter
      use password <- form.parameter
      LoginSubmission(type_: submission_type, password: password)
    })
    |> form.with_values(formdata.values)
    |> form.field(
      "username_or_email",
      form.string |> form.and(parse_login_submission_type),
    )
    |> form.field(
      "password",
      form.string
        |> form.and(password.create),
    )
    |> form.finish

  case result {
    Ok(data) -> {
      case login(app_ctx.db, data) {
        Ok(#(session_key, seconds_until_expiration)) -> {
          wisp.redirect("/")
          |> wisp.set_cookie(
            req,
            "session",
            user_session.key_to_string(session_key),
            wisp.Signed,
            seconds_until_expiration,
          )
        }
        Error(InvalidCredentials) -> {
          // Timing obfuscation + poor man's rate-limiting
          process.sleep(int.random(201) + 100)
          login.login_page(view_ctx, form.new(), Some("Invalid credentials"))
          |> wisp.html_response(401)
        }
        Error(UnknownLoginError) -> {
          login.login_page(
            view_ctx,
            form.new(),
            Some("An error occurred trying to authenticate"),
          )
          |> wisp.html_response(500)
        }
      }
    }
    Error(form) -> {
      login.login_page(view_ctx, form, None)
      |> wisp.html_response(422)
    }
  }
}
