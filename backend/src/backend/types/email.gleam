import gleam/bool
import gleam/dynamic.{type Dynamic}
import gleam/io
import gleam/list
import gleam/result
import gleam/string

pub opaque type EmailAddress {
  EmailAddress(value: String)
}

// https://thecopenhagenbook.com/email-verification#input-validation
pub fn parse(str: String) -> Result(EmailAddress, String) {
  let error = Error("Invalid email")

  let str = string.trim(str)
  use <- bool.guard(string.is_empty(str), error)
  use <- bool.guard(string.length(str) > 255, error)

  use #(head, domain) <- result.try({
    case string.split(str, "@") {
      [head, domain] -> Ok(#(head, domain))
      [head, ..tail] -> {
        use <- bool.guard(list.is_empty(tail), Error("Invalid email"))
        let assert Ok(domain) = list.last(tail)
        Ok(#(head, domain))
      }
      _ -> Error("Invalid email")
    }
  })

  use <- bool.guard(string.is_empty(head), error)
  use <- bool.guard(string.is_empty(domain), error)

  use <- bool.guard(
    {
      case string.split(domain, ".") {
        [_head, ..tail] -> {
          case tail {
            [] -> True
            _ -> False
          }
        }
        _ -> True
      }
    },
    error,
  )

  Ok(EmailAddress(str))
}

pub fn to_string(email: EmailAddress) -> String {
  email.value
}

/// This is only used for fetching from SQL,
/// which has assumably already been validated
pub fn decode_sql_email(d: Dynamic) {
  use str <- result.try(dynamic.string(d))
  Ok(EmailAddress(str))
  // case parse(str) {
  //   Error(_) -> Error([DecodeError(expected: "email", found: "?", path: [])])
  //   Ok(email) -> Ok(email)
  // }
}

pub type EmailMessage {
  EmailMessage(recipients: List(EmailAddress), subject: String, body: String)
}

pub fn print_email_message(msg: EmailMessage) -> Result(Nil, String) {
  let recipients = msg.recipients |> list.map(to_string) |> string.join("; ")

  io.println("----- EMAIL -----")
  io.println("To: " <> recipients)
  io.println("Subject: " <> msg.subject)
  io.println(msg.body)
  io.println("----- END EMAIL -----")

  Ok(Nil)
}
