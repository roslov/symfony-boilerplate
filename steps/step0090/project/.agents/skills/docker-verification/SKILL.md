---
name: docker-verification
description: >-
  Enforce Docker-only execution and run verification commands (static analysis, coding style,
  unit tests, and integration tests) for the ${PROJECT_FULL_NAME} (${PROJECT_NAME}) service.
  Use when validating changes, running tests, or checking code before completion.
---

# Docker Verification Workflow

All build, test, and verification workflows for **${PROJECT_FULL_NAME}** (`${PROJECT_NAME}`) must be executed strictly
within Docker containers.

## Execution Environment Model

Commands in this repository are strictly segregated into two distinct execution contexts:

1. **Host Machine / WSL (Project Root Folder)**:
   - Docker commands (such as `docker compose exec ${PROJECT_NAME} <cmd>`) and Makefile commands (such as
     `make validate`, `make shell`, `make build`, `make up`, `make down`) are executed in the project root folder on the
     host machine or WSL.
   - **Never** install packages, libraries, or runtimes directly on the host machine or in WSL.

2. **Docker Container (`${PROJECT_NAME}` service / working directory `/app`)**:
   - All PHP and Composer project commands (`composer test:static`, `composer test:unit`, `composer test:integration`,
     `rector`, `composer phpcbf .`, `codecept run`, `bin/console`, etc.) are executed inside the Docker container.
   - Run directly inside the container shell (`make shell`), or invoke from the host via
     `docker compose exec ${PROJECT_NAME} <cmd>`.

> [!CAUTION]
> **Host / WSL Installation Prohibition**
> Agents are strictly prohibited from installing PHP, Composer, or tools directly on the host machine or in WSL. All
> project execution, dependency installation, and validation must occur inside Docker containers. Agents are also
> strictly prohibited from modifying `Dockerfile` and files under `.docker/` unless strictly requested.

> [!IMPORTANT]
> **No Unverified Completion**
> No task may be declared complete while a required verification command is failing, skipped without explanation, or
> unexecuted.

---

## Verification Commands Quick Reference

### Host Machine / WSL

Execute Docker and Makefile commands in the project root folder on the host machine/WSL:

```bash
# Run full validation pipeline (static analysis, unit tests, integration tests)
make validate

# Open an interactive shell inside the service container
make shell

# Or execute commands directly via Docker Compose from the deployment root:
docker compose exec ${PROJECT_NAME} composer test:static
docker compose exec ${PROJECT_NAME} composer test:unit
docker compose exec ${PROJECT_NAME} composer test:integration
```

---

## Commands Executed Inside the Docker Container (`/app`)

When working inside the `${PROJECT_NAME}` container shell (e.g., via `make shell`), run project commands directly:

### 1. Static Analysis & Code Quality

- **Run full static suite**:
  ```bash
  composer test:static
  ```
  This command sequentially runs:
  1. `composer validate`: Validates `composer.json` and `composer.lock`.
  2. `composer normalize --dry-run`: Verifies `composer.json` formatting via `ergebnis/composer-normalize`.
  3. `composer syntax .`: Checks PHP syntax errors across the project using `parallel-lint`.
  4. `bin/console lint:container`: Validates the Symfony dependency injection service container.
  5. `bin/console lint:yaml config src tests`: Validates YAML configuration files.
  6. `composer phpcs .`: Checks `PSR12Ext` (`roslov/psr12ext`) coding standards via `ruleset.xml`.
  7. `codecept build`: Generates Codeception test actors (`UnitTester`, `FunctionalTester`).
  8. `composer phpstan`: Performs PHPStan `level: max` static analysis with `512M` memory limit.
  9. `rector --dry-run`: Asserts automated architecture and modern PHP refactoring rules.

- **Automated code fixing (Rector & PHPCBF)**:
  ```bash
  # Run Rector twice to ensure cascading AST rules converge
  rector
  rector

  # Automatically fix PHP_CodeSniffer coding style violations
  composer phpcbf .
  ```

- **Run individual static tools**:
  ```bash
  composer syntax .
  composer phpcs .
  composer phpstan
  ```

### 2. Unit, Functional, and Integration Tests (`tests/Unit`, `tests/Functional`)

- **Run all unit and functional tests**:
  ```bash
  composer test:unit
  ```
  (Equivalent to `codecept run`).

- **Run integration tests**:
  ```bash
  composer test:integration
  ```

- **Run targeted Codeception suites**:
  ```bash
  codecept run Unit
  codecept run Functional
  ```

---

## Pre-Completion Checklist

Before marking any task as complete:

1. **PHPDoc Documentation & Strict Types**:
   Ensure all new or modified classes, interfaces, traits, methods, properties, and constants have detailed PHPDoc doc
   blocks and `declare(strict_types=1);`.
2. **Environment Configuration**:
   Ensure `.env` and `.env.test` reflect all configuration variables with safe development defaults and zero secrets.
3. **Docker Protection**:
   Ensure `Dockerfile` and files under `.docker/` were not modified unless strictly requested.
4. **Markdown Line Limit**:
   Ensure all modified or newly created Markdown files (`*.md`) strictly adhere to the 120-character line limit.
5. **Execute Full Verification**:
   Execute `make validate` or containerized checks (`composer test:static`, `composer test:unit`, and
   `composer test:integration`). All tests and checks must pass cleanly.
6. **Final Reporting**:
   List changed files, verification commands executed, test results, and any remaining risks.
7. **Git Commit Policy**:
   Do not create git commits or push changes without an explicit user request.

---

## Skill Maintenance & Self-Enforcement

Whenever changing build configurations, Composer scripts, PHPStan settings, test suites, or Docker definitions, update
this skill file (`.agents/skills/docker-verification/SKILL.md`) to reflect the current workflow.
