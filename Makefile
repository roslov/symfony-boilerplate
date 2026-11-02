# This is a development Makefile. It should be run on a host machine

# Default command
.DEFAULT_GOAL := help

# Gets the current Makefile. It is used to display help from this file only
CURRENT_FILE := $(lastword $(MAKEFILE_LIST))

# Disables echoing of recipe lines (the commands) before running them
.SILENT:

# Default shell — bash
SHELL := /usr/bin/env bash
.SHELLFLAGS := -eu -o pipefail -c

# Docker Composer run commands
DOCKER_COMPOSE_RUN := \
	HOST_USER="$(shell id -un)" \
	HOST_GROUP="$(shell id -gn)" \
	HOST_UID="$(shell id -u)" \
	HOST_GID="$(shell id -g)" \
	docker compose run --rm boilerplate

# ======================================================================================================================
# === Targets ==========================================================================================================
# ======================================================================================================================

#
# Development
#

build: ## Creates a microservice
	[[ -f .env ]] || cp .env.dist .env
	./create-microservice.sh

shell: ## Gets into container’s shell
	$(DOCKER_COMPOSE_RUN) bash

#
# Testing
#

test: syntax static unit integration ## Runs all tests

syntax: ## Checks script syntax
	bash -n create-microservice.sh

static: ## Runs static analysis
	$(DOCKER_COMPOSE_RUN) composer test:static

unit: ## Runs unit tests
	$(DOCKER_COMPOSE_RUN) composer test:unit

integration: ## Runs integration tests
	$(DOCKER_COMPOSE_RUN) composer test:integration

#
# Help
#

help: ## Shows this help
	@awk 'BEGIN { printf "\nUsage:\n  make \033[36m<target> [<target2> ...]\033[0m\n" } \
	/^#$$/ { blank = 1; next } \
	blank && /^# [a-zA-Z]/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 3); blank = 0; next } \
	/^[a-zA-Z_-]+:([^=]|$$)/ { \
		split($$0, parts, "##"); \
		target = parts[1]; sub(/:.*/, "", target); \
		desc = parts[2]; \
		gsub(/^[[:space:]]+|[[:space:]]+$$/, "", desc); \
		printf "  \033[36m%-25s\033[0m %s\n", target, desc; \
		blank = 0; \
	}' $(CURRENT_FILE)
