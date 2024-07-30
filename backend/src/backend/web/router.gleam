import backend/features/index
import backend/features/login
import backend/features/register
import backend/middleware/session
import backend/middleware/tracing
import backend/types/username
import backend/web/context.{type AppContext}
import gleam/option.{None, Some}
import gleam/string
import shared/dtos/global_view_context
import shared/dtos/users
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, app_ctx: AppContext) -> Response {
  use <- wisp.log_request(req)
  use span_ctx <- tracing.trace_request(req)
  use <- tracing.trace_and_rescue_crashes(span_ctx)
  use user <- session.derive_user(req, app_ctx.db)

  let route = wisp.path_segments(req)
  let view_ctx =
    global_view_context.GlobalViewContext(
      app_name: app_ctx.config.app_name,
      page_title: app_ctx.config.app_name,
      current_route: "/" <> string.join(route, "/"),
      user: case user {
        None -> None
        Some(user) ->
          Some(users.CurrentUserSession(
            username: user.username |> username.to_string(),
            display_name: user.display_name,
          ))
      },
    )

  let req_ctx = context.RequestContext(user: user, view_context: view_ctx)

  use <- wisp.serve_static(
    req,
    under: "/static",
    from: app_ctx.static_directory,
  )

  case wisp.path_segments(req) {
    [] -> index.index(req, app_ctx, req_ctx)
    ["login"] -> login.login_handler(req, app_ctx, req_ctx)
    ["register"] -> register.register_handler(req, app_ctx, req_ctx)
    ["register", "confirm"] -> register.confirm_handler(req, app_ctx, req_ctx)
    _ -> wisp.not_found()
  }
}
