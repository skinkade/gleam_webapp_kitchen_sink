import gleam/list
import gleam/pgo
import gleam/regex
import gleam/result
import gleam/string
import glotel/span

/// The automatic instrumentation does not include errors
pub fn sql(sql, conn, params, decoder) {
  let assert Ok(whitespace) = regex.from_string("\\s+")
  let sql = sql |> string.trim()
  let operation =
    sql
    |> regex.split(whitespace, _)
    |> list.find(fn(token) {
      list.contains(
        ["SELECT", "INSERT", "UPDATE", "DELETE", "CREATE"],
        string.uppercase(token),
      )
    })
    |> result.unwrap("QUERY")
    |> string.uppercase()

  use span_ctx <- span.new("SQL " <> operation, [
    #("db.operation.name", operation),
    #("db.query.text", sql),
  ])

  case pgo.execute(sql, conn, params, decoder) {
    Error(e) -> {
      span.set_error(span_ctx)
      span.set_attribute(span_ctx, "error.type", string.inspect(e))
      Error(e)
    }
    ok -> ok
  }
}
