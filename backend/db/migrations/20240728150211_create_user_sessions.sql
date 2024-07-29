-- migrate:up

CREATE TABLE user_sessions (
    id INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    token_hash BYTEA NOT NULL,
    user_id INT NOT NULL
        REFERENCES users (id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expired_at TIMESTAMPTZ NOT NULL
);

CREATE UNIQUE INDEX UX_user_session_token_hash
ON user_sessions (token_hash);

CREATE INDEX IX_user_session_user
ON user_sessions (user_id)
INCLUDE (expired_at);

-- migrate:down

DROP TABLE user_sessions;
