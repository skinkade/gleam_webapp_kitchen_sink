import backend/types/email.{type EmailAddress}
import backend/types/password.{type Password}
import backend/types/time
import backend/types/username.{type Username}
import backend/util/traced
import birl.{type Time}
import gleam/dynamic.{type Dynamic}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/pgo.{type Connection}
import gleam/result

pub type UserId {
  UserId(value: Int)
}

pub fn id_to_int(id: UserId) -> Int {
  id.value
}

pub fn decode_user_id(d: Dynamic) {
  use value <- result.try(dynamic.int(d))
  Ok(UserId(value))
}

pub type User {
  User(
    id: UserId,
    email_address: EmailAddress,
    username: Username,
    display_name: Option(String),
    password_hash: String,
    created_at: Time,
    updated_at: Time,
  )
}

pub fn decode_user_sql(d: Dynamic) {
  let decoder =
    dynamic.decode7(
      User,
      dynamic.element(0, decode_user_id),
      dynamic.element(1, email.decode_sql_email),
      dynamic.element(2, username.decode_sql_username),
      dynamic.element(3, dynamic.optional(dynamic.string)),
      dynamic.element(4, dynamic.string),
      dynamic.element(5, time.dynamic_time),
      dynamic.element(6, time.dynamic_time),
    )

  decoder(d)
}

pub fn create(
  db: Connection,
  email: EmailAddress,
  username: username.Username,
  password: Password,
) -> Result(User, pgo.QueryError) {
  let sql =
    "
        INSERT INTO users
        (email_address, username, password_hash)
        VALUES
        ($1, $2, $3)
        RETURNING
            id,
            email_address,
            username,
            display_name,
            password_hash,
            created_at::text,
            updated_at::text;
    "

  let password_hash = password.hash(password)

  use response <- result.try({
    traced.sql(
      sql,
      db,
      [
        email |> email.to_string() |> pgo.text(),
        username |> username.to_string() |> pgo.text(),
        password_hash |> pgo.text(),
      ],
      decode_user_sql,
    )
  })

  let assert Ok(user) = list.first(response.rows)
  Ok(user)
}

pub fn get_by_id(
  conn: Connection,
  id: UserId,
) -> Result(Option(User), pgo.QueryError) {
  let sql =
    "
    SELECT
        id,
        email_address,
        username,
        display_name,
        password_hash,
        created_at::text,
        updated_at::text
    FROM users
    WHERE id = $1
  "

  use result <- result.try({
    traced.sql(sql, conn, [id.value |> pgo.int()], decode_user_sql)
  })

  case result.rows {
    [] -> Ok(None)
    [user] -> Ok(Some(user))
    _ -> panic as "Unreachable"
  }
}

pub fn get_by_email(
  conn: Connection,
  email: EmailAddress,
) -> Result(Option(User), pgo.QueryError) {
  let sql =
    "
        SELECT
            id,
            email_address,
            username,
            display_name,
            password_hash,
            created_at::text,
            updated_at::text
        FROM users
        WHERE email_address = $1
    "

  use result <- result.try({
    traced.sql(
      sql,
      conn,
      [email |> email.to_string() |> pgo.text()],
      decode_user_sql,
    )
  })

  case result.rows {
    [] -> Ok(None)
    [user] -> Ok(Some(user))
    _ -> panic as "Unreachable"
  }
}

pub fn get_by_username(
  conn: Connection,
  username: Username,
) -> Result(Option(User), pgo.QueryError) {
  let sql =
    "
    SELECT
        id,
        email_address,
        username,
        display_name,
        password_hash,
        created_at::text,
        updated_at::text
    FROM users
    WHERE username = $1
  "

  use result <- result.try({
    traced.sql(
      sql,
      conn,
      [username |> username.to_string() |> pgo.text()],
      decode_user_sql,
    )
  })

  case result.rows {
    [] -> Ok(None)
    [user] -> Ok(Some(user))
    _ -> panic as "Unreachable"
  }
}
