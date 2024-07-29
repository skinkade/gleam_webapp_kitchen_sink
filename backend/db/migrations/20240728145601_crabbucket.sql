-- migrate:up

CREATE SCHEMA IF NOT EXISTS crabbucket;

CREATE UNLOGGED TABLE IF NOT EXISTS crabbucket.token_buckets (
    id TEXT PRIMARY KEY,
    window_end BIGINT NOT NULL,
    remaining_tokens INT NOT NULL
);

CREATE INDEX IF NOT EXISTS IX_token_bucket_window_end
ON crabbucket.token_buckets (window_end);

-- migrate:down

DROP TABLE crabbucket.token_buckets;
