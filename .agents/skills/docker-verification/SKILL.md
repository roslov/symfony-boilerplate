---
name: docker-verification
description: >-
  Enforce Docker-only PHP/Composer execution and run verification commands (shell syntax check,
  microservice generation, static analysis, and unit/functional tests) for the Symfony Microservice
  Boilerplate. Use when validating changes to create-microservice.sh, steps/, or docker/.
---

# Docker Verification Workflow

All PHP, Composer, static analysis, and test workflows for the Symfony Microservice Boilerplate must be executed
strictly within the `boilerplate` Docker container.

## Execution Environment Model

Commands in this repository are segregated into two distinct execution contexts:

1. **Host Machine / WSL (Repository Root)**:
   - Used to run `bash -n create-microservice.sh`, `./create-microservice.sh` (or `make build`), `make` targets
     (`make test`, `make static`, `make unit`, `make integration`, `make shell`, `make help`), and `docker compose`
     commands.
   - `compose.yaml` requires `HOST_USER`, `HOST_GROUP`, `HOST_UID`, and `HOST_GID` environment variables when building
     or running `docker compose` directly on the host (automatically provided by `Makefile` and
     `create-microservice.sh`).
   - **Never** install PHP, Composer, or PHP packages directly on the host machine or in WSL.

2. **Docker Container (`boilerplate` service / working directory `/app` mounted from `./app`)**:
   - All PHP and Composer commands (`composer test:static`, `composer test:unit`, `composer test:integration`,
     `rector`, `composer phpcbf .`, `codecept run`, `bin/console`, etc.) execute inside the `boilerplate` container
     against `/app`.

> [!CAUTION]
> **Host / WSL Installation Prohibition**
> Agents are strictly prohibited from installing PHP, Composer, or tools directly on the host machine or in WSL. All
> PHP/Composer execution, dependency installation, and validation must occur inside Docker containers. Agents are also
> strictly prohibited from modifying `docker/Dockerfile` and files under `docker/image-files/` unless strictly
> requested.

> [!IMPORTANT]
> **No Unverified Completion**
> No task may be declared complete while a required verification command is failing, skipped without explanation, or
> unexecuted.

---

## Verification Commands Quick Reference

### 1. Validate Generator Script Syntax (Host)

```bash
bash -n create-microservice.sh
```

### 2. Run Full Microservice Generation Pipeline (Host + Docker)

Requires `.env` (copied from `.env.dist`) and network access to Packagist:

```bash
# Creates .env from .env.dist if missing and runs ./create-microservice.sh
make build
```

Or run the script directly:

```bash
cp -n .env.dist .env
./create-microservice.sh
```

### 3. Run Verification Against an Existing `./app` Directory (Host -> Docker)

When `./app` is already generated, run checks inside the `boilerplate` container using the root `Makefile` (which
automatically passes `HOST_USER`, `HOST_GROUP`, `HOST_UID`, and `HOST_GID`):

```bash
# Run all tests (static, unit, and integration)
make test

# Or run individual suites / open container shell:
make static
make unit
make integration
make shell
```

Or run `docker compose` directly by exporting the host user variables:

```bash
export HOST_USER="$(id -un)"
export HOST_GROUP="$(id -gn)"
export HOST_UID="$(id -u)"
export HOST_GID="$(id -g)"

# Run full static analysis suite in ./app
docker compose run --rm boilerplate composer test:static

# Run Codeception Unit and Functional tests in ./app
docker compose run --rm boilerplate composer test:unit

# Run integration test script in ./app
docker compose run --rm boilerplate composer test:integration
```

---

## What `composer test:static` Executes Inside `/app`

```bash
docker compose run --rm boilerplate composer test:static
```

Sequentially runs:

1. `composer validate`: Validates `composer.json` and `composer.lock`.
2. `composer normalize --dry-run`: Verifies `composer.json` formatting via `ergebnis/composer-normalize`.
3. `composer syntax .`: Checks PHP syntax across the project using `parallel-lint`.
4. `bin/console lint:container`: Validates the Symfony dependency injection service container.
5. `bin/console lint:yaml config src tests`: Validates YAML configuration files.
6. `composer phpcs .`: Checks `PSR12Ext` coding standards via `ruleset.xml`.
7. `codecept build`: Generates Codeception test actors (`UnitTester`, `FunctionalTester`).
8. `composer phpstan`: Performs PHPStan `level: max` static analysis with `stubs/CodeceptionExample.stub`.
9. `rector --dry-run`: Asserts automated architecture and modern PHP refactoring rules.

### Automated Code Fixing Inside `/app`

As implemented in `fixAndValidateFiles()` in `create-microservice.sh`:

```bash
# Run Rector twice to ensure cascading AST rules converge
docker compose run --rm boilerplate rector
docker compose run --rm boilerplate rector

# Auto-fix PHP_CodeSniffer issues
docker compose run --rm boilerplate composer phpcbf .
```

---

## Pre-Completion Checklist

Before marking any task as complete:

1. **Shell Syntax & Pipeline Integrity**:
   Ensure `bash -n create-microservice.sh` passes with zero errors.
2. **PHPDoc Documentation & Strict Types**:
   Ensure all PHP files under `steps/` have detailed PHPDoc doc blocks and `declare(strict_types=1);`.
3. **Environment Configuration**:
   Ensure `.env.dist` reflects all generator variables with safe placeholder defaults and zero secrets.
4. **Docker Protection**:
   Ensure `docker/Dockerfile` and files under `docker/image-files/` were not modified unless strictly requested.
5. **Markdown Line Limit**:
   Ensure all modified or newly created Markdown files (`*.md`) strictly adhere to the 120-character line limit.
6. **Execute Verification**:
   Run container verification checks (`composer test:static`, `composer test:unit`, `composer test:integration`) if
   `./app` is present, or run `./create-microservice.sh` when testing pipeline changes.
7. **Git Commit Policy**:
   Do not create git commits or push changes without an explicit user request.

---

## Skill Maintenance & Self-Enforcement

Whenever changing Docker image settings, `compose.yaml`, the root `Makefile`, `create-microservice.sh` verification
functions, or Composer test scripts, update this skill file (`.agents/skills/docker-verification/SKILL.md`) to reflect
the current workflow.
