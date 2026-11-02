# Acceptance Criteria

## Configuration and Environment

- [x] All generator environment variables (`SYMFONY_VERSION`, `REPO_SITE`, `VENDOR`, `PROJECT_NAME`,
  `PROJECT_FULL_NAME`, `PROJECT_DESCRIPTION`, `PARENT_PROJECT_FULL_NAME`) are defined in `.env.dist` and documented in
  `docs/requirements.md`.
- [x] `.env` and `/app/` are listed in the root `.gitignore` and never committed to the repository.
- [x] `.env.dist` contains safe example defaults with zero secrets or production credentials.
- [x] Host and WSL PHP/Composer installation prohibitions are documented and enforced across all workflows.

## Docker Image and Permission Model

- [x] `docker/Dockerfile` builds a PHP 8.5 (`IMAGE_TAG=8.5.5`) and Composer 2.9 (`COMPOSER_VERSION=2.9.7`) container
  with `bcmath`, `gd`, `intl`, `pcntl`, `sockets`, and `zip` extensions.
- [x] `compose.yaml` passes `HOST_USER`, `HOST_GROUP`, `HOST_UID`, and `HOST_GID` build arguments so container processes
  run under the host user's UID/GID without requiring `sudo`.
- [x] Root `Makefile` provides `build`, `shell`, `test`, `static`, `unit`, `integration`, and `help` targets that
  automatically pass `HOST_*` variables to `docker compose run --rm boilerplate`.
- [x] PHP INI configurations (`base-custom.ini` and `custom.ini`) set `date.timezone = UTC` and `memory_limit = 512M`.

## Bootstrapping Pipeline and Step Templates

- [x] `bash -n create-microservice.sh` passes with zero syntax errors.
- [x] Running `./create-microservice.sh` recreates `app/`, initializes the `main` branch, and records atomic `[init]`
  commits for each step from `step0010` through `step1010`.
- [x] `envsubst` calls specify explicit variable lists so unrelated `$` strings in templates are preserved.
- [x] `normalizeComposer` runs `composer bump` and `composer normalize` whenever `composer.json` is modified.
- [x] `fixAndValidateFiles` runs Rector twice, `composer phpcbf .`, `composer test:static`, and `composer test:unit`
  before committing code steps.

## Generated Microservice Quality and Tooling

- [x] Generated `composer.json` requires `php:>=8.5`, replaces PHP 7.2-8.5 polyfills, and includes
  `roslov/queue-bundle`, `symfony/monolog-bundle`, `symfony/serializer`, `codeception/codeception`,
  `phpstan/phpstan-symfony`, `rector/rector`, and `roslov/psr12ext`.
- [x] Full static analysis passes cleanly inside the container via `composer test:static` (`composer validate`,
  `composer normalize --dry-run`, `parallel-lint`, `lint:container`, `lint:yaml`, `phpcs`, `codecept build`, `phpstan`
  at `level: max`, and `rector --dry-run`).
- [x] Unit and Functional test suites (`ExampleTest` and `ExampleCest`) pass cleanly via `composer test:unit`.
- [x] Monolog is configured with rotating files in `dev`/`test` and stderr JSON stack traces at `info` action level in
  `prod`.
- [x] `roslov/queue-bundle` and `old_sound_rabbit_mq` are configured with `App\Consumer\ExampleConsumer` bound to queue
  `${PROJECT_NAME}-some-example` on the `common` topic exchange.
- [x] Generated microservices include `AGENTS.md`, `docs/` (`requirements.md`, `architecture.md`, `security.md`,
  `testing.md`, `acceptance-criteria.md`), and `.agents/skills/` (`docker-verification`, `testing`,
  `queue-and-messaging`) rendered in `step0090`.
- [x] All PHP files in `steps/` enforce `declare(strict_types=1);` and have complete PHPDoc doc blocks.
- [x] All Markdown documentation files (`*.md`) strictly adhere to the 120-character line length limit.
- [x] Workspace skills under `.agents/skills/` accurately document current repository workflows and templates.
