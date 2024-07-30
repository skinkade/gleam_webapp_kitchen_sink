import backend/middleware/rate_limiting
import backend/middleware/view_context
import backend/models/pending_registration
import backend/types/email.{type EmailAddress}
import backend/types/password
import backend/types/username
import backend/web/context.{type AppContext, type RequestContext}
import formal/form
import gleam/bool
import gleam/dict
import gleam/http.{Get, Post}
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import lustre/attribute
import lustre/element
import lustre/element/html
import shared/views/register
import wisp.{type Request, type Response}

pub fn register_handler(
  req: Request,
  app_ctx: AppContext,
  req_ctx: RequestContext,
) {
  case req.method {
    Get -> register_form(req_ctx)
    Post -> submit_register_form(req, app_ctx, req_ctx)
    _ -> wisp.method_not_allowed([Get, Post])
  }
}

pub fn confirm_handler(
  req: Request,
  app_ctx: AppContext,
  req_ctx: RequestContext,
) {
  case req.method {
    Get -> confirmation_form(req, app_ctx, req_ctx)
    Post -> submit_confirmation_form(req, app_ctx, req_ctx)
    _ -> wisp.method_not_allowed([Get, Post])
  }
}

fn register_form(req_ctx) -> Response {
  // Create a new empty Form to render the HTML form with.
  // If the form is for updating something that already exists you may want to
  // use `form.initial_values` to pre-fill some fields.
  let form = form.new()

  let view_ctx = view_context.get("Register", req_ctx)

  register.register_page(view_ctx, form, None)
  |> wisp.html_response(200)
}

const registration_submission_rate_window = 300_000

const registration_ip_rate_limit = 5

fn submit_register_form(
  req: Request,
  app_ctx: AppContext,
  req_ctx: RequestContext,
) -> Response {
  use <- rate_limiting.rate_limit_by_ip(
    req,
    app_ctx,
    ["register", "submit"],
    registration_submission_rate_window,
    registration_ip_rate_limit,
  )

  let view_ctx = view_context.get("Register", req_ctx)
  use formdata <- wisp.require_form(req)

  let result =
    form.decoding({
      use email <- form.parameter
      email
    })
    |> form.with_values(formdata.values)
    |> form.field("email", form.string |> form.and(email.parse))
    |> form.finish

  case result {
    Ok(email) -> {
      case pending_registration.create(app_ctx.db, email) {
        Ok(pending_registration_token) -> {
          let email_attempt =
            create_invite_email(
              app_ctx.config.app_address,
              email,
              pending_registration_token,
            )
            |> app_ctx.services.send_email()
          case email_attempt {
            Error(e) -> {
              io.debug(e)
              register.register_page(
                view_ctx,
                form.new(),
                Some("An error occurred trying to create your account"),
              )
              |> wisp.html_response(500)
            }
            Ok(Nil) -> {
              register.email_sent_page(view_ctx)
              |> wisp.html_response(201)
            }
          }
        }
        Error(e) -> {
          io.debug(e)
          register.register_page(
            view_ctx,
            form.new(),
            Some("An error occurred trying to create your account"),
          )
          |> wisp.html_response(500)
        }
      }
    }

    Error(form) -> {
      register.register_page(view_ctx, form, None)
      |> wisp.html_response(500)
    }
  }
}

pub fn create_invite_email(
  app_address: String,
  address: EmailAddress,
  token: pending_registration.PendingRegistrationToken,
) {
  let link = app_address <> "/register/confirm?token=" <> token.value
  let body =
    html.html([attribute.attribute("lang", "en")], [
      html.head([], [
        html.meta([attribute.attribute("charset", "UTF-8")]),
        html.meta([
          attribute.attribute("name", "viewport"),
          attribute.attribute(
            "content",
            "width=device-width, initial-scale=1.0",
          ),
        ]),
      ]),
      html.body([], [html.a([attribute.href(link)], [html.text(link)])]),
    ])
    |> element.to_string

  email.EmailMessage(
    recipients: [address],
    subject: "Kitchen Sink Registration Link",
    body: body,
  )
}

fn query_token(req) {
  req |> wisp.get_query() |> list.key_find("token")
}

fn confirmation_form(
  req: Request,
  app_ctx: AppContext,
  req_ctx: RequestContext,
) -> Response {
  let view_ctx = view_context.get("Register", req_ctx)

  let token = query_token(req)
  use <- bool.lazy_guard(result.is_error(token), fn() {
    register.invalid_or_expired_confirmation_token(view_ctx)
    |> wisp.html_response(404)
  })
  let assert Ok(token) = token

  let invite =
    pending_registration.get_valid_registration_by_token(app_ctx.db, token)
  use <- bool.guard(result.is_error(invite), wisp.internal_server_error())

  let assert Ok(invite) = invite
  use <- bool.lazy_guard(option.is_none(invite), fn() {
    register.invalid_or_expired_confirmation_token(view_ctx)
    |> wisp.html_response(404)
  })

  let assert Some(invite) = invite
  let form =
    form.initial_values([
      #("token", token),
      #("email", email.to_string(invite.email_address)),
    ])

  register.confirm_page(view_ctx, form, None)
  |> wisp.html_response(200)
}

pub type ConfirmationSubmission {
  ConfirmationSubmission(
    token: String,
    username: username.Username,
    password: password.Password,
  )
}

fn submit_confirmation_form(
  req: Request,
  app_ctx: AppContext,
  req_ctx: RequestContext,
) -> Response {
  let view_ctx = view_context.get("Confirm Registration", req_ctx)
  let token = query_token(req)
  use <- bool.lazy_guard(result.is_error(token), fn() {
    register.invalid_or_expired_confirmation_token(view_ctx)
    |> wisp.html_response(404)
  })
  let assert Ok(token) = token

  let invite =
    pending_registration.get_valid_registration_by_token(app_ctx.db, token)
  use <- bool.lazy_guard(result.is_error(invite), fn() {
    let _ = io.debug(invite)
    wisp.internal_server_error()
  })

  let assert Ok(invite) = invite
  use <- bool.lazy_guard(option.is_none(invite), fn() {
    register.invalid_or_expired_confirmation_token(view_ctx)
    |> wisp.html_response(404)
  })
  let assert Some(invite) = invite

  let password_policy = password.PasswordPolicy(min_length: 12, max_length: 50)
  use formdata <- wisp.require_form(req)

  let result =
    form.decoding({
      use token <- form.parameter
      use username <- form.parameter
      use password <- form.parameter
      ConfirmationSubmission(
        token: token,
        username: username,
        password: password,
      )
    })
    |> form.with_values(formdata.values)
    |> form.field("token", form.string |> form.and(form.must_not_be_empty))
    |> form.field("username", form.string |> form.and(username.parse))
    |> form.field(
      "password",
      form.string
        |> form.and(password.create)
        |> form.and(password.policy_compliant(_, password_policy)),
    )
    |> form.finish

  case result {
    Ok(data) -> {
      case
        pending_registration.try_register(
          app_ctx.db,
          data.token,
          data.username,
          data.password,
        )
      {
        Ok(user) -> {
          io.debug(user)
          use <- bool.lazy_guard(option.is_none(user), fn() {
            register.invalid_or_expired_confirmation_token(view_ctx)
            |> wisp.html_response(404)
          })
          wisp.redirect("/login")
        }
        Error(e) -> {
          io.debug(e)
          register.confirm_page(
            view_ctx,
            form.initial_values([
              #("token", token),
              #("email", email.to_string(invite.email_address)),
            ]),
            Some("An error occurred trying to create your account"),
          )
          |> wisp.html_response(500)
        }
      }
    }

    Error(form) -> {
      io.debug(form)
      let form =
        form.Form(
          values: form.values
            |> dict.insert("email", [email.to_string(invite.email_address)])
            |> dict.insert("token", [token]),
          errors: form.errors,
        )
      register.confirm_page(view_ctx, form, None)
      |> wisp.html_response(422)
    }
  }
}
