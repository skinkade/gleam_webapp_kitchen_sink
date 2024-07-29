import backend/web/context
import shared/dtos/global_view_context.{GlobalViewContext}

pub fn get(title: String, req_ctx: context.RequestContext) {
  GlobalViewContext(
    ..req_ctx.view_context,
    page_title: title <> " | KitchenSink",
  )
}
