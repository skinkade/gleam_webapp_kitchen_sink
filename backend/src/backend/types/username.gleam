import gleam/bool
import gleam/dynamic.{type Dynamic}
import gleam/regex
import gleam/result
import gleam/string

pub opaque type Username {
  Username(value: String)
}

pub fn parse(str: String) -> Result(Username, String) {
  let str = string.trim(str)
  use <- bool.guard(
    string.length(str) < 3,
    Error("Username must be at least 3 characters"),
  )
  use <- bool.guard(
    string.length(str) < 3,
    Error("Username must be 25 characters or less"),
  )

  let assert Ok(nick_regex) = regex.from_string("[a-zA-Z0-9][a-zA-Z0-9-_]+")
  use <- bool.guard(
    !regex.check(nick_regex, str),
    Error(
      "Username must start with a letter or number, and may contain only letters, numbers, underscores (_) and dashes (-)",
    ),
  )

  Ok(Username(str))
}

pub fn to_string(username: Username) -> String {
  username.value
}

/// This is only used for fetching from SQL,
/// which has assumably already been validated
pub fn decode_sql_username(d: Dynamic) {
  use str <- result.try(dynamic.string(d))
  Ok(Username(str))
}
