# Symfony Microservice Boilerplate

This repository contains an automated bootstrapping tool for generating a new PHP microservice repository based on the
Symfony framework, preconfigured with coding standards, static analysis, automated refactoring, testing suites, logging,
RabbitMQ message queue integration, and CI/CD pipeline templates.

Running the generator produces a ready-to-push Git repository inside the `app/` directory with a clean, step-by-step
history of `[init]` commits.

## Core behavior

The boilerplate generator provides:

- automated initialization of a new Symfony skeleton project inside an isolated Docker container;
- sequential execution of modular provisioning steps (`steps/step0010` through `steps/step1010`);
- automatic creation of atomic `[init] <description>` Git commits on the `main` branch for each provisioning stage;
- preconfigured Composer metadata, PHP `>=8.5` requirement, polyfill replacements, `composer bump`, and
  `ergebnis/composer-normalize`;
- strict static analysis and coding style tooling: `php-parallel-lint`, `PHP_CodeSniffer` with `roslov/psr12ext`,
  `PHPStan` (`level: max`) with `phpstan/phpstan-symfony`, and `Rector` (`rector/rector`);
- `Codeception` (`Unit` and `Functional` suites) with `Asserts` and `Symfony` modules and example tests;
- environment-aware `Monolog` configuration (rotating file logs in `dev`/`test`, JSON logs with stack traces on
  `stderr` at `info` action level in `prod`);
- asynchronous messaging setup via `roslov/queue-bundle` and `php-amqplib/rabbitmq-bundle` with an example consumer
  (`App\Consumer\ExampleConsumer`);
- development `Makefile` and `Jenkinsfile` CI pipeline templates rendered via `envsubst`.

## Technology

- Bash bootstrapping pipeline (`create-microservice.sh`) and host `Makefile`
- Docker and Docker Compose (`docker/Dockerfile`, `compose.yaml`)
- PHP 8.5 (`IMAGE_TAG=8.5.5`) with strict types (`declare(strict_types=1);`)
- Composer 2.9 (`COMPOSER_VERSION=2.9.7`) with `ergebnis/composer-normalize`
- Symfony skeleton (`SYMFONY_VERSION` configured in `.env`, e.g., `8.1`)
- Roslov Queue Bundle (`roslov/queue-bundle`) and RabbitMQ (`php-amqplib/rabbitmq-bundle`)
- Codeception 5.3 (`codeception/codeception`, `codeception/module-asserts`, `codeception/module-symfony`)
- PHPStan (`level: max`) with `phpstan/phpstan-symfony`
- PHP_CodeSniffer with `roslov/psr12ext` (`PSR12Ext` ruleset)
- Rector 2 (`rector/rector`) for automated PHP and Symfony refactoring rules
- Jenkins declarative pipeline (`Jenkinsfile`)

## Architecture

The repository is organized as follows:

- `create-microservice.sh`: Main Bash orchestration script that builds the Docker image, initializes `./app`, and
  applies every step in sequence while validating and committing the result;
- `Makefile`: Host development `Makefile` providing helper targets (`build`, `shell`, `test`, `static`, `unit`,
  `integration`, `help`) that automatically pass `HOST_*` user/group variables to `docker compose`;
- `compose.yaml`: Docker Compose definition for the `boilerplate` service mounting `./app` to `/app`;
- `docker/`: Container build context (`Dockerfile` and `image-files/` with PHP INI configurations and helper scripts);
- `steps/`: Ordered step directories (`step0010` to `step1010`) containing templates, configurations, and stubs copied
  or rendered into the target microservice;
- `.env.dist`: Template environment variables defining target microservice metadata and Symfony version;
- `app/`: Output directory (git-ignored) containing the generated microservice repository and its `.git` history.

See:

- [`AGENTS.md`](AGENTS.md)
- [`docs/requirements.md`](docs/requirements.md)
- [`docs/architecture.md`](docs/architecture.md)
- [`docs/security.md`](docs/security.md)
- [`docs/testing.md`](docs/testing.md)
- [`docs/acceptance-criteria.md`](docs/acceptance-criteria.md)

## Prerequisites

- Docker and Docker Compose
- Bash, `git`, `make`, and `envsubst` (from `gettext-base`) on the host machine

All PHP, Composer, static analysis, and test executions run strictly inside the `boilerplate` Docker container. Agents
and contributors must not install PHP or Composer packages on the host machine or WSL.

## Configuration

Copy `.env.dist` to `.env` and customize the variables for the target microservice:

| Variable                   | Example Value              | Description                                               |
|----------------------------|----------------------------|-----------------------------------------------------------|
| `SYMFONY_VERSION`          | `8.1`                      | Major.minor Symfony skeleton version (`symfony/skeleton`) |
| `REPO_SITE`                | `github.com`               | Git hosting domain used in generated documentation links  |
| `VENDOR`                   | `yourvendor`               | Composer vendor prefix and repository organization        |
| `PROJECT_NAME`             | `example`                  | Short microservice slug (`composer.json`, queues)         |
| `PROJECT_FULL_NAME`        | `"Microservice Example"`   | Human-readable service title for `README.md` & Composer   |
| `PROJECT_DESCRIPTION`      | `"This is a full..."`      | Multiline overview inserted into generated `README.md`    |
| `PARENT_PROJECT_FULL_NAME` | `"Global Project Example"` | Parent ecosystem/project name referenced in `README.md`   |

## How to create a new microservice

1. Copy `.env.dist` to `.env`:
   ```sh
   cp .env.dist .env
   ```
2. Edit `.env` with the target microservice settings (`SYMFONY_VERSION`, `VENDOR`, `PROJECT_NAME`, etc.).
3. Run the generator from the repository root using `make` (or `./create-microservice.sh` directly):
   ```sh
   make build
   ```
4. Inspect the generated microservice and its Git commit log inside the `app/` directory:
   ```sh
   git -C app log --oneline
   ```
5. Push the contents of the `app/` directory to the new microservice repository.
6. Register the new microservice in the `deployment` repository alongside existing services.

## Verification commands

When modifying `create-microservice.sh`, `steps/`, or `docker/`, verify the changes using the following commands from
the repository root:

```sh
# 1. Check Bash script syntax
bash -n create-microservice.sh

# 2. Run the full microservice generation pipeline (creates .env if missing and runs ./create-microservice.sh)
make build

# 3. Run all static analysis, unit, and integration tests against an already generated ./app directory
make test

# Or run individual test suites via make:
make static
make unit
make integration

# Equivalent direct Docker Compose commands:
HOST_USER="$(id -un)" HOST_GROUP="$(id -gn)" HOST_UID="$(id -u)" HOST_GID="$(id -g)" \
    docker compose run --rm boilerplate composer test:static

HOST_USER="$(id -un)" HOST_GROUP="$(id -gn)" HOST_UID="$(id -u)" HOST_GID="$(id -g)" \
    docker compose run --rm boilerplate composer test:unit

HOST_USER="$(id -un)" HOST_GROUP="$(id -gn)" HOST_UID="$(id -u)" HOST_GID="$(id -g)" \
    docker compose run --rm boilerplate composer test:integration
```

## Contribution workflow

1. Read [`AGENTS.md`](AGENTS.md) and the documentation under [`docs/`](docs/).
2. Keep changes focused on the requested boilerplate step, script, or Docker configuration.
3. Preserve strict typing (`declare(strict_types=1);`), `PSR12Ext` compliance, and detailed PHPDoc blocks in all PHP
   templates under `steps/`.
4. Keep `.env.dist` accurate with safe placeholder values and zero secrets.
5. Verify changes by running `bash -n create-microservice.sh` and validating the generated microservice in `app/`.
6. Update `README.md`, `docs/`, and `.agents/skills/` whenever steps, tools, or workflows change.
7. Do not create Git commits or push changes without an explicit user request.

## Frequently asked questions (FAQ)

### Why does `create-microservice.sh` export `HOST_USER`, `HOST_GROUP`, `HOST_UID`, and `HOST_GID`?

The `boilerplate` Docker image creates a matching user and group inside the container so that all files generated in the
mounted `./app` directory are owned by your host user rather than `root`, avoiding `sudo` or permission issues.

### How do I enable Doctrine support in a generated microservice?

`create-microservice.sh` contains `# TODO: Uncomment for Doctrine support` markers in the PHPStan step. Uncomment those
lines when bootstrapping a service that uses Doctrine ORM so `phpstan/phpstan-doctrine` is installed and included in
`phpstan.dist.neon`.
