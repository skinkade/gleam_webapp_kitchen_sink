# A kitchen sink full of Gleam web app tech demos

## Requirements

- Gleam + Erlang
- Docker or Podman
- dbmate for migrations
- npm for Tailwind

## Usage

Generate CSS:

```shell
cd shared

make css-watch
# or `make css-minify`
```

Set up config / environment variables, instantiate Postgres DB, run app:

```shell
cd backend

cp .envrc.example .envrc
echo "export WISP_SECRET_KEY='$(head -c32 /dev/urandom | base64)'" >> .envrc

direnv allow # if you use direnv
source .envrc # if you don't

make db-up

gleam run
```