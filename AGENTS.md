# AGENTS.md

## Purpose

This repository contains the **Symfony Microservice Boilerplate**, a Dockerized generator tool that bootstraps new
PHP 8.5 / Symfony microservices (such as the `api`, `cron`, `mailer`, and `alerts` services in downstream ecosystems).
Executing `./create-microservice.sh` builds a PHP 8.5 + Composer container (`boilerplate`), initializes a new Symfony
skeleton project in `./app`, applies ordered configuration steps from `steps/step0010` through `steps/step1010`, runs
Rector, PHP_CodeSniffer, PHPStan (`level: max`), and Codeception tests after each stage, and records a clean series of
`[init] ...` Git commits on the `main` branch.

Every change to `create-microservice.sh`, `steps/`, or `docker/` directly affects the baseline architecture, coding
standards, and CI pipelines of all newly generated microservices.

This file is mandatory guidance for all automated agents and human contributors.

## Required reading

Before changing code or templates, read:

- `README.md`
- `docs/requirements.md`
- `docs/architecture.md`
- `docs/security.md`
- `docs/testing.md`
- `docs/acceptance-criteria.md`

## Scope discipline

- Implement only the requested task.
- Do not silently resolve product ambiguity with a broad assumption.
- Record a material unresolved decision in the task report.
- Keep pull requests narrow and reviewable.
- Do not mix unrelated refactoring with functional changes.
- Do not modify `docker/Dockerfile`, `docker/image-files/`, or `compose.yaml` unless strictly requested.
- Do not commit `app/` or `.env` (both are git-ignored).
- Do not edit `.idea/` files.
- Agents are not allowed to install PHP, Composer, or project dependencies on the host machine or WSL and must use
  Docker containers only.
- Never commit or push changes to git without an explicit user request.

## Execution environment

The repository operates across two contexts:

1. **Host Machine / WSL (Repository Root)**:
   - Used to run `bash -n create-microservice.sh`, `./create-microservice.sh` (or `make build`), `make` targets
     (`make test`, `make static`, `make unit`, `make integration`, `make shell`), and `docker compose` commands.
   - `compose.yaml` requires `HOST_USER`, `HOST_GROUP`, `HOST_UID`, and `HOST_GID` environment variables when building
     or running the `boilerplate` container so generated files in `./app` match the host user's ownership (automatically
     set by `Makefile` and `create-microservice.sh`).
2. **Docker Container (`boilerplate` service, working directory `/app` mounted from `./app`)**:
   - All PHP, Composer, Rector, PHPCS, PHPStan, Symfony Console, and Codeception commands execute inside the
     `boilerplate` container (`docker compose run --rm boilerplate <cmd>`).

See `.agents/skills/docker-verification/SKILL.md` for detailed command patterns.

## Architectural boundaries

Repository files are organized into distinct layers:

- `create-microservice.sh`: Orchestrates the end-to-end microservice generation workflow, helper functions
  (`fixAndValidateFiles`, `normalizeComposer`, `commit`), Composer package installations, `jq` / `php -r` / `sed` /
  `envsubst` transformations, and step commits.
- `Makefile`: Host development `Makefile` providing `build`, `shell`, `test`, `static`, `unit`, `integration`, and
  `help` targets that automatically pass `HOST_*` user/group variables to `docker compose run --rm boilerplate`.
- `steps/`: Modular provisioning steps applied in numerical order:
  - `steps/step0010/`: `.gitignore` IDE exclusions prepended to Symfony's default `.gitignore`.
  - `steps/step0020/`: `.editorconfig` and `.gitattributes` templates.
  - `steps/step0030/`: Initial `README.md` template rendered with `envsubst`.
  - `steps/step0038/`: Host development `Makefile` template delegating targets to the parent deployment `Makefile`.
  - `steps/step0040/`: `ruleset.xml` (`roslov/psr12ext`), `coding-style.md`, and `faq.md` snippets.
  - `steps/step0045/`: `monolog.yaml` with rotating file handlers for `dev`/`test` and stderr JSON logging for `prod`.
  - `steps/step0050/`: `codeception.yml` fragment, `tests.md` snippet, `tests/bootstrap.php`,
    `tests/Unit/ExampleTest.php`, and `tests/Functional/ExampleCest.php`.
  - `steps/step0060/`: `stubs/CodeceptionExample.stub` for PHPStan `level: max` compatibility.
  - `steps/step0070/`: `roslov/queue-bundle` and `old_sound_rabbit_mq` configuration templates, `parameters.yaml`,
    `consumers.md`, and `src/Consumer/ExampleConsumer.php`.
  - `steps/step0080/`: `rector.php` configuration with strict PHP, Symfony, Doctrine, and PHPUnit prepared sets.
  - `steps/step1010/`: `Jenkinsfile` declarative CI/CD pipeline template.
- `docker/`: Container image definition (`Dockerfile` with PHP 8.5 and Composer 2.9) and container filesystem overlay
  (`docker/image-files/`).
- `compose.yaml`: Defines the `boilerplate` service mounting `./app:/app` and loading `.env.dist` and `.env`.
- `.env.dist`: Default configuration template for microservice generation variables.
- `app/`: Git-ignored target directory where the generated microservice repository is constructed.

## Boilerplate pipeline and step template rules

- Keep `create-microservice.sh` idempotent from a clean run (it recreates `app/` from scratch and initializes a fresh
  `main` branch).
- Always pass an explicit variable whitelist to `envsubst` (e.g., `envsubst '${PROJECT_NAME}'`) so unrelated
  `$variables` in Markdown or configuration files are not accidentally stripped.
- After modifying `composer.json` in a provisioning step, run `normalizeComposer` (`composer bump` and
  `composer normalize`).
- After adding or modifying PHP, YAML, or configuration files in a provisioning step (once static analysis tools are
  installed), run `fixAndValidateFiles` before calling `commit`.
- Prefix every generated Git commit message with `[init] ` via the `commit "<message>"` helper function.
- Notice that `fixAndValidateFiles` runs `rector` twice (`docker compose run --rm boilerplate rector` x2) to guarantee
  convergent refactoring before running `composer phpcbf .`, `composer test:static`, and `composer test:unit`.

## Generated microservice code & quality rules

All PHP templates under `steps/` and any code generated into `app/` must satisfy the generated project's quality gates:

- Declare `declare(strict_types=1);` at the top of every PHP file (except stub files where namespace rules differ).
- Follow `PSR12Ext` (`roslov/psr12ext`) coding standards configured in `steps/step0040/ruleset.xml`.
- Pass PHPStan at `level: max` with `phpstan/phpstan-symfony` and `stubs/CodeceptionExample.stub`.
- Pass `rector --dry-run` using `steps/step0080/rector.php` with zero pending changes.
- Pass `bin/console lint:container` and `bin/console lint:yaml config src tests`.
- Pass `composer validate` and `composer normalize --dry-run`.
- Include comprehensive PHPDoc doc blocks on all classes, methods, properties, and constants.

## Testing rules

Every change to the boilerplate generator or its step templates must be verified:

1. **Shell Script Syntax**:
   - Validate `create-microservice.sh` syntax using `bash -n create-microservice.sh`.
2. **Generated Microservice Static Analysis (`composer test:static`)**:
   - Must pass `@composer validate`, `@composer normalize --dry-run`, `@syntax .`, `bin/console lint:container`,
     `bin/console lint:yaml config src tests`, `@phpcs .`, `codecept build`, `@phpstan`, and `rector --dry-run`.
3. **Generated Microservice Unit & Functional Tests (`composer test:unit`)**:
   - Codeception `Unit` (`Tests\Unit\ExampleTest`) and `Functional` (`Tests\Functional\ExampleCest`) suites must pass
     cleanly.

## Required commands

Before declaring a task complete, run the appropriate verification commands:

```bash
# Validate shell script syntax
bash -n create-microservice.sh

# If ./app is already generated and you are verifying template/code changes inside ./app:
make test
# Or run individual suites (make static / make unit / make integration) or via docker compose directly:
HOST_USER="$(id -un)" HOST_GROUP="$(id -gn)" HOST_UID="$(id -u)" HOST_GID="$(id -g)" \
    docker compose run --rm boilerplate composer test:static
HOST_USER="$(id -un)" HOST_GROUP="$(id -gn)" HOST_UID="$(id -u)" HOST_GID="$(id -g)" \
    docker compose run --rm boilerplate composer test:unit
HOST_USER="$(id -un)" HOST_GROUP="$(id -gn)" HOST_UID="$(id -u)" HOST_GID="$(id -g)" \
    docker compose run --rm boilerplate composer test:integration
```

When modifying `create-microservice.sh` or step provisioning logic, run `make build` / `./create-microservice.sh`
(requires `.env` and network access to Packagist) or report the exact blocker if offline. Do not represent an unexecuted
check as passing.

## Code documentation rules

- All PHP classes, interfaces, traits, methods, properties, and constants in `steps/` must have detailed PHPDoc doc
  blocks (`@param`, `@return`, `@throws`, `@inheritDoc`).
- Maintain `declare(strict_types=1);` in all PHP source and test files.
- Comment each provisioning block in `create-microservice.sh` clearly with section headers.

## Documentation requirements

Update `README.md` and `docs/` when changing:

- environment variables in `.env.dist`, `compose.yaml`, or root `Makefile` targets;
- provisioning steps in `create-microservice.sh` or files under `steps/`;
- Composer packages, scripts, or quality tools installed into generated microservices;
- Docker base image tags (`IMAGE_TAG`, `COMPOSER_VERSION`), PHP extensions, or helper scripts under `docker/`;
- RabbitMQ / `roslov/queue-bundle`, Monolog, Codeception, PHPStan, PHPCS, Rector, Makefile, or Jenkinsfile templates.

All Markdown documentation files (`*.md`) must strictly adhere to the 120-character line length limit.

## Skill maintenance rules

Whenever changing functionality or workflows, update the corresponding workspace skill under `.agents/skills/`:

- Docker execution, `HOST_*` variables, root `Makefile` targets, verification commands, or container setup ->
  `.agents/skills/docker-verification/SKILL.md`
- Adding or modifying provisioning steps in `steps/` or `create-microservice.sh` ->
  `.agents/skills/boilerplate-steps-and-pipeline/SKILL.md`
- Updating PHPCS (`ruleset.xml`), PHPStan, Rector (`rector.php`), or Codeception templates ->
  `.agents/skills/code-quality-and-testing-templates/SKILL.md`
- Updating Queue bundle (`roslov/queue-bundle`), RabbitMQ, Monolog, `Makefile`, or `Jenkinsfile` templates ->
  `.agents/skills/queue-and-service-templates/SKILL.md`

## Definition of done

Work is complete only when:

- the requested behavior is implemented;
- all PHP files in `steps/` have detailed PHPDoc doc blocks and `declare(strict_types=1);`;
- `.env.dist` is maintained, accurate, and contains safe placeholder defaults with zero secrets;
- no software, tools, or dependencies were installed on the host machine or WSL, and all PHP/Composer execution
  occurred strictly inside Docker containers;
- `docker/Dockerfile` and files under `docker/image-files/` remain untouched unless strictly requested;
- acceptance criteria in `docs/acceptance-criteria.md` are satisfied;
- `bash -n create-microservice.sh` and required container verification commands pass;
- `README.md` and `docs/` describe the resulting behavior;
- relevant workspace skills under `.agents/skills/` are updated to reflect the resulting behavior;
- all Markdown files strictly adhere to the 120-character line length limit;
- no git commits or pushes are made without an explicit user request;
- the final report lists changed files, checks run, and remaining risks.
