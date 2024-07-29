-- migrate:up

CREATE EXTENSION IF NOT EXISTS citext;

CREATE TABLE users (
    id INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    email_address citext NOT NULL,
    username citext NOT NULL,
    display_name TEXT,
    password_hash TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX UX_user_email_address
ON users (email_address);

CREATE UNIQUE INDEX UX_user_username
ON users (username);

-- migrate:down

DROP TABLE users;
