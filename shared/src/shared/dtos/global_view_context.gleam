import gleam/option.{type Option}
import shared/dtos/users

pub type GlobalViewContext {
  GlobalViewContext(
    page_title: String,
    current_route: String,
    user: Option(users.CurrentUserSession),
  )
}
