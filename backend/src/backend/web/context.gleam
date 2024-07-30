import backend/models/user.{type User}
import backend/types/email.{type EmailMessage}
import gleam/option.{type Option}
import gleam/pgo.{type Connection}
import shared/dtos/global_view_context.{type GlobalViewContext}

pub type Services {
  Services(send_email: fn(EmailMessage) -> Result(Nil, String))
}

pub type Config {
  Config(
    app_name: String,
    app_address: String,
    ip_address_http_headers: List(String),
  )
}

pub type AppContext {
  AppContext(
    db: Connection,
    static_directory: String,
    services: Services,
    config: Config,
  )
}

pub type RequestContext {
  RequestContext(user: Option(User), view_context: GlobalViewContext)
}
