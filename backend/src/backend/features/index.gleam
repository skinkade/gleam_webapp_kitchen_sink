import backend/middleware/view_context
import shared/layouts/base_layout
import wisp

pub fn index(_req, _app_ctx, req_ctx) {
  let view_ctx = view_context.get("Main", req_ctx)
  base_layout.default(view_ctx, [])
  |> wisp.html_response(200)
}
