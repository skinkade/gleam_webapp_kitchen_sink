import exception
import gleam/dict
import gleam/dynamic
import gleam/erlang/atom
import gleam/http.{method_to_string}
import gleam/int
import gleam/list
import gleam/string
import glotel/span.{type SpanContext}
import glotel/span_kind
import wisp.{type Request, type Response}

pub fn trace_request(
  request: Request,
  handler: fn(span.SpanContext) -> Response,
) -> Response {
  let method = method_to_string(request.method)
  let query =
    wisp.get_query(request)
    |> list.map(fn(q) {
      let #(k, v) = q
      case string.lowercase(k) == "token" {
        True -> k <> "=REDACTED"
        False -> k <> "=" <> v
      }
    })
    |> string.join("&")
  let path = case string.is_empty(query) {
    True -> "/" <> { wisp.path_segments(request) |> string.join("/") }
    False ->
      "/" <> { wisp.path_segments(request) |> string.join("/") } <> "?" <> query
  }

  span.extract_values(request.headers)

  use span_ctx <- span.new_of_kind(span_kind.Server, method <> " " <> path, [
    #("http.request.method", method),
    #("url.path", path),
  ])

  let response = handler(span_ctx)

  span.set_attribute(
    span_ctx,
    "http.response.status_code",
    int.to_string(response.status),
  )

  case response.status >= 500 {
    True -> span.set_error(span_ctx)
    _ -> Nil
  }

  response
}

type DoNotLeak

@external(erlang, "logger", "error")
fn log_error_dict(o: dict.Dict(atom.Atom, dynamic.Dynamic)) -> DoNotLeak

type ErrorKind {
  Errored
  Thrown
  Exited
}

/// Alternative to wisp.rescue_crashes() 
pub fn trace_and_rescue_crashes(
  span_ctx: SpanContext,
  handler: fn() -> Response,
) -> Response {
  case exception.rescue(handler) {
    Ok(response) -> response
    Error(error) -> {
      let #(kind, detail) = case error {
        exception.Errored(detail) -> #(Errored, detail)
        exception.Thrown(detail) -> #(Thrown, detail)
        exception.Exited(detail) -> #(Exited, detail)
      }

      span.set_error_message(
        span_ctx,
        string.inspect(kind) <> ": " <> string.inspect(detail),
      )

      case dynamic.dict(atom.from_dynamic, Ok)(detail) {
        Ok(details) -> {
          let c = atom.create_from_string("class")
          log_error_dict(dict.insert(details, c, dynamic.from(kind)))
          Nil
        }
        Error(_) -> wisp.log_error(string.inspect(error))
      }
      wisp.internal_server_error()
    }
  }
}
