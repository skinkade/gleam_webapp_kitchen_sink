import backend/types/email
import backend/web/context.{AppContext, Config, Services}
import backend/web/router
import crabbucket/pgo as crabbucket
import envoy
import gleam/erlang/process
import gleam/option
import gleam/pgo
import gleam/result
import gleam/string
import mist
import wisp

pub fn main() {
  wisp.configure_logger()

  let assert Ok(app_name) = envoy.get("APP_NAME")
  let assert Ok(app_address) = envoy.get("APP_ADDRESS")

  let secret_key_base =
    envoy.get("WISP_SECRET_KEY")
    |> result.lazy_unwrap(fn() { wisp.random_string(64) })

  let assert Ok(database_host) = envoy.get("DATABASE_HOST")
  let assert Ok(database_name) = envoy.get("DATABASE_NAME")
  let assert Ok(database_user) = envoy.get("POSTGRES_USER")
  let database_password =
    envoy.get("POSTGRES_PASSWORD")
    |> option.from_result()

  let db =
    pgo.connect(
      pgo.Config(
        ..pgo.default_config(),
        host: database_host,
        user: database_user,
        password: database_password,
        database: database_name,
        pool_size: 15,
      ),
    )

  let ip_address_http_headers =
    envoy.get("IP_ADDRESS_HEADERS")
    |> result.map(fn(s) {
      let s = s |> string.trim() |> string.lowercase()
      case s {
        "" -> []
        s -> string.split(s, ",")
      }
    })
    |> result.unwrap([])

  let context =
    AppContext(
      db: db,
      static_directory: static_directory(),
      services: Services(send_email: email.print_email_message),
      config: Config(
        app_name: app_name,
        app_address: app_address,
        ip_address_http_headers: ip_address_http_headers,
      ),
    )

  let _token_bucket_cleaner = crabbucket.create_and_start_cleaner(db, 1000 * 60)

  let handler = router.handle_request(_, context)

  let assert Ok(_) =
    wisp.mist_handler(handler, secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start_http

  process.sleep_forever()
}

pub fn static_directory() -> String {
  let assert Ok(priv_directory) = wisp.priv_directory("backend")
  priv_directory <> "/static"
}
