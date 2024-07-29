-- migrate:up

CREATE TABLE pending_registrations (
    id INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    email_address citext NOT NULL,
    token_hash BYTEA NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expired_at TIMESTAMPTZ NOT NULL
);

CREATE UNIQUE INDEX UX_pending_user_token_hash
ON pending_registrations (token_hash);

CREATE UNIQUE INDEX UX_pending_user_email
ON pending_registrations (email_address);

-- migrate:down

DROP TABLE pending_registrations;
