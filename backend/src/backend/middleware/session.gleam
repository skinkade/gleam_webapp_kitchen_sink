import backend/models/user
import backend/models/user_session
import backend/web/context.{type RequestContext}
import gleam/bool
import gleam/io
import gleam/option.{type Option, None, Some}
import gleam/pgo
import gleam/result
import wisp.{type Request, type Response}

pub fn derive_session(
  req: Request,
  conn: pgo.Connection,
  handler: fn(Option(user_session.SessionQueryRecord)) -> Response,
) -> Response {
  let session = wisp.get_cookie(req, "session", wisp.Signed)
  use <- bool.lazy_guard(result.is_error(session), fn() { handler(None) })

  let assert Ok(session) = session
  let session = user_session.get_by_session_key_string(conn, session)
  use <- bool.lazy_guard(result.is_error(session), fn() {
    let _ = io.debug(session)
    wisp.internal_server_error()
  })

  let assert Ok(session) = session
  use <- bool.lazy_guard(option.is_none(session), fn() { handler(None) })

  let assert Some(session) = session
  use <- bool.lazy_guard(user_session.is_expired(session), fn() {
    handler(None)
  })

  handler(Some(session))
}

pub fn derive_user(
  req: Request,
  conn: pgo.Connection,
  handler: fn(Option(user.User)) -> Response,
) -> Response {
  use session <- derive_session(req, conn)
  use <- bool.lazy_guard(option.is_none(session), fn() { handler(None) })

  let assert Some(session) = session
  let user = user.get_by_id(conn, session.user_id)
  use <- bool.lazy_guard(result.is_error(user), fn() {
    let _ = io.debug(user)
    wisp.internal_server_error()
  })

  let assert Ok(Some(user)) = user
  //   use <- bool.guard(user.disabled_or_locked(user), handler(None))

  handler(Some(user))
}

pub fn require_user(
  req_ctx: RequestContext,
  handler: fn(user.User) -> Response,
) -> Response {
  use <- bool.lazy_guard(option.is_some(req_ctx.user), fn() {
    wisp.redirect("/login")
  })
  let assert Some(user) = req_ctx.user
  handler(user)
}
