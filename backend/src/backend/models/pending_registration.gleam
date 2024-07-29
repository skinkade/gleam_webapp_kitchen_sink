import backend/models/user
import backend/types/email
import backend/types/password
import backend/types/time
import backend/types/username
import backend/util/traced
import birl.{type Time}
import birl/duration
import gleam/bit_array
import gleam/bool
import gleam/crypto
import gleam/dynamic.{type Dynamic}
import gleam/option.{type Option, None, Some}
import gleam/pgo.{type Connection}
import gleam/result
import wisp

pub type PendingRegistration {
  PendingRegistration(
    email_address: email.EmailAddress,
    created_at: Time,
    expired_at: Time,
  )
}

pub fn decode_pending_registration_sql(d: Dynamic) {
  let decoder =
    dynamic.decode3(
      PendingRegistration,
      dynamic.element(0, email.decode_sql_email),
      dynamic.element(1, time.dynamic_time),
      dynamic.element(2, time.dynamic_time),
    )

  decoder(d)
}

pub type PendingRegistrationToken {
  PendingRegistrationToken(value: String)
}

const default_invite_duration_minutes = 15

pub fn create(
  db: Connection,
  email: email.EmailAddress,
) -> Result(PendingRegistrationToken, pgo.QueryError) {
  let sql =
    "
        INSERT INTO pending_registrations
        (email_address, token_hash, expired_at)
        VALUES
        ($1, $2, $3)
        ON CONFLICT (email_address)
        DO UPDATE SET
            token_hash = $2,
            expired_at = $3;
    "

  let invite_token = wisp.random_string(32)
  let token_hash =
    crypto.hash(crypto.Sha256, invite_token |> bit_array.from_string())

  let now = birl.utc_now()
  let expiration =
    now |> birl.add(duration.minutes(default_invite_duration_minutes))

  use _ <- result.try({
    traced.sql(
      sql,
      db,
      [
        email |> email.to_string() |> pgo.text(),
        token_hash |> pgo.bytea(),
        expiration |> birl.to_erlang_universal_datetime() |> pgo.timestamp(),
      ],
      dynamic.dynamic,
    )
  })

  Ok(PendingRegistrationToken(invite_token))
}

pub fn remove_invite_by_email(
  db: Connection,
  email: email.EmailAddress,
) -> Result(Nil, pgo.QueryError) {
  let sql =
    "
        DELETE FROM pending_registrations
        WHERE email_address = $1;
    "

  use _ <- result.try({
    traced.sql(
      sql,
      db,
      [email |> email.to_string() |> pgo.text()],
      dynamic.dynamic,
    )
  })

  Ok(Nil)
}

pub fn get_valid_registration_by_token(
  conn: Connection,
  token: String,
) -> Result(Option(PendingRegistration), pgo.QueryError) {
  let hash = crypto.hash(crypto.Sha256, bit_array.from_string(token))

  let sql =
    "
        SELECT
            email_address,
            created_at::text,
            expired_at::text
        FROM pending_registrations
        WHERE token_hash = $1
            AND expired_at > now()
    "

  use result <- result.try({
    traced.sql(
      sql,
      conn,
      [hash |> pgo.bytea()],
      decode_pending_registration_sql,
    )
  })

  case result.rows {
    [pending_registration] -> Ok(Some(pending_registration))
    _ -> Ok(None)
  }
}

pub fn try_register(
  conn: Connection,
  invite_token: String,
  username: username.Username,
  password: password.Password,
) -> Result(Option(user.User), pgo.TransactionError) {
  use conn <- pgo.transaction(conn)

  let assert Ok(pending) = get_valid_registration_by_token(conn, invite_token)

  use <- bool.guard(option.is_none(pending), Ok(None))
  let assert Some(pending) = pending

  // TODO: handle if user with this email already exists
  let assert Ok(user) =
    user.create(conn, pending.email_address, username, password)
  let assert Ok(Nil) = remove_invite_by_email(conn, pending.email_address)

  Ok(Some(user))
}
