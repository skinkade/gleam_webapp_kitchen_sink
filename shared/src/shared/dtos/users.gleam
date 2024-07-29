import gleam/option.{type Option, Some}

pub type CurrentUserSession {
  CurrentUserSession(username: String, display_name: Option(String))
}

pub fn user_display_text(user: CurrentUserSession) -> String {
  case user.display_name {
    Some(s) -> s
    _ -> user.username
  }
}
