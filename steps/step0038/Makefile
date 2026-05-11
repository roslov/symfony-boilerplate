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

# ======================================================================================================================
# === Targets ==========================================================================================================
# ======================================================================================================================

#
# Run
#

up: ## Ups the dev environment
	$(MAIN_MAKE) up

down: ## Downs the dev environment
	$(MAIN_MAKE) down

#
# Development
#

build: ## Builds this service
	$(MAIN_MAKE) build-$(SERVICE)

shell: ## Gets into container shell of this service
	$(MAIN_MAKE) shell-$(SERVICE)

validate: ## Validates and tests this service
	$(MAIN_MAKE) validate-$(SERVICE)

#
# XDebug
#

enable-xdebug: ## Enables XDebug for this service
	$(MAIN_MAKE) enable-xdebug-$(SERVICE)

disable-xdebug: ## Disables XDebug for this service
	$(MAIN_MAKE) disable-xdebug-$(SERVICE)

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
	}' $(MAKEFILE_LIST)
