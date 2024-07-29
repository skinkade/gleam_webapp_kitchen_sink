SHELL=/bin/bash

.PHONY: run
run:
	watchexec --restart --verbose --clear --wrap-process=session --stop-signal SIGTERM --exts gleam --watch src/ -- "gleam run"


DOCKER_COMPOSE_COMMAND := $(or $(shell which podman-compose),$(shell which docker-compose))

.PHONY: db-up
db-up:
	source ./.envrc && $(DOCKER_COMPOSE_COMMAND) up -d && sleep 5 && dbmate migrate

.PHONY: db-down
db-down:
	$(DOCKER_COMPOSE_COMMAND) down

.PHONY: db-delete
db-delete:
	$(DOCKER_COMPOSE_COMMAND) down -v

.PHONY: build-prod
build-prod:
	gleam export erlang-shipment

DOCKER_COMMAND := $(or $(shell which podman),$(shell which docker))

.PHONY: container-build
container-build:
	$(DOCKER_COMMAND) build --file ./Dockerfile --tag kitchensink

.PHONY: container-run
container-run:
	$(DOCKER_COMMAND) run -e DATABASE_NAME=kitchensink_dev -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -e DATABASE_HOST=host.containers.internal --replace -p 8000:8000 --name kitchensink localhost/kitchensink:latest
