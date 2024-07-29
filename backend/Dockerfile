FROM ghcr.io/gleam-lang/gleam:v1.3.2-erlang-alpine AS build

COPY . /build
RUN rm -rf /build/build

RUN apk add gcc build-base npm bash elixir \
    && cd /build \
    && make css-minify \
    && mix local.hex --force \
    && make build-prod \
    && mv build/erlang-shipment /app \
    && cd / \
    && rm -rf /build \
    && apk del gcc build-base npm bash elixir

ENV USER=app
ENV GROUPNAME=$USER
ENV UID=1000
ENV GID=1000

RUN addgroup \
    --gid "$GID" \
    "$GROUPNAME" \
&&  adduser \
    --disabled-password \
    --ingroup "$GROUPNAME" \
    --no-create-home \
    --uid "$UID" \
    $USER
RUN chown app:app /app

WORKDIR /app
USER app
EXPOSE 8000
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run"]
