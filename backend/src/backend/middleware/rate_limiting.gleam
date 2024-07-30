import backend/web/context
import crabbucket/pgo as crabbucket
import gleam/int
import gleam/io
import gleam/list
import gleam/pgo.{type Connection}
import gleam/result
import gleam/string
import wisp

fn set_header_if_not_present(resp: wisp.Response, name: String, value: String) {
  case list.key_find(resp.headers, name) {
    Ok(_) -> resp
    Error(_) -> resp |> wisp.set_header(name, value)
  }
}

const limit_header = "x-rate-limit-limit"

const remaining_header = "x-rate-limit-remaining"

const reset_header = "x-rate-limit-reset"

pub fn rate_limit(
  conn: Connection,
  key: String,
  window_duration_ms: Int,
  default_token_count: Int,
  handler: fn() -> wisp.Response,
) -> wisp.Response {
  let limit_result =
    crabbucket.remaining_tokens_for_key(
      conn,
      key,
      window_duration_ms,
      default_token_count,
    )

  case limit_result {
    Error(crabbucket.PgoError(e)) -> {
      io.debug(e)
      wisp.internal_server_error()
    }
    Error(crabbucket.MustWaitUntil(next_reset)) -> {
      wisp.response(429)
      |> wisp.set_header(limit_header, default_token_count |> int.to_string())
      |> wisp.set_header(remaining_header, "0")
      |> wisp.set_header(reset_header, next_reset |> int.to_string())
    }
    Ok(crabbucket.HasRemainingTokens(tokens, next_reset)) -> {
      handler()
      |> set_header_if_not_present(
        limit_header,
        default_token_count |> int.to_string(),
      )
      |> set_header_if_not_present(remaining_header, tokens |> int.to_string())
      |> set_header_if_not_present(reset_header, next_reset |> int.to_string())
    }
  }
}

pub fn rate_limit_by_ip(
  req: wisp.Request,
  app_ctx: context.AppContext,
  key_parts: List(String),
  window_duration_ms: Int,
  default_token_count: Int,
  handler: fn() -> wisp.Response,
) -> wisp.Response {
  let header =
    app_ctx.config.ip_address_http_headers
    |> list.map(list.key_find(find: _, in: req.headers))
    |> list.find(result.is_ok)
  let ip = case header {
    Ok(Ok(ip)) -> ip
    _ -> "IP_NOT_FOUND"
  }

  let key = string.join(key_parts, "/") <> "/ip/" <> ip

  use <- rate_limit(app_ctx.db, key, window_duration_ms, default_token_count)
  handler()
}
