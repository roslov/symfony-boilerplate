# This is a development Makefile. It should be run on a host machine

# Current service
SERVICE := ${PROJECT_NAME}

# Default command
.DEFAULT_GOAL := help

# Disables echoing of recipe lines (the commands) before running them
.SILENT:

# Default shell — bash
SHELL := /usr/bin/env bash
.SHELLFLAGS := -eu -o pipefail -c

# Main Makefile
MAIN_MAKE := $(MAKE) -C ../..

# === Targets ===

up: ## Ups the dev environment
	$(MAIN_MAKE) up

down: ## Downs the dev environment
	$(MAIN_MAKE) down

build: ## Builds this service
	$(MAIN_MAKE) build-$(SERVICE)

shell: ## Gets into container shell of this service
	$(MAIN_MAKE) shell-$(SERVICE)

validate: ## Validates and tests this service
	$(MAIN_MAKE) validate-$(SERVICE)

enable-xdebug: ## Enables XDebug for this service
	$(MAIN_MAKE) enable-xdebug-$(SERVICE)

disable-xdebug: ## Disables XDebug for this service
	$(MAIN_MAKE) disable-xdebug-$(SERVICE)

# === Help ===

# Outputs the help for each task, see https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help: ## Shows this help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
