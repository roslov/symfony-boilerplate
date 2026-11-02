# Testing Strategy and Guide

## Overview

Verification in the **Symfony Microservice Boilerplate** operates at two levels:

1. **Generator Pipeline Verification**: Ensuring `create-microservice.sh` has valid Bash syntax, executes all steps
   cleanly inside Docker, and produces the expected sequence of `[init]` Git commits in `./app`.
2. **Generated Microservice Verification**: Running the full static analysis and automated test suites inside the
   `boilerplate` container against the generated code in `/app` (`./app` on the host).

---

## 1. Verifying the generator script

Before running or committing changes to `create-microservice.sh`:

```bash
# Check Bash syntax without executing the script
bash -n create-microservice.sh
```

To run an end-to-end test of the generator (requires `.env` and network access to install Composer packages), use
`make build` (which creates `.env` from `.env.dist` if missing and runs `./create-microservice.sh`):

```bash
make build
```

Or directly via the script:

```bash
cp -n .env.dist .env
./create-microservice.sh
```

During execution, `create-microservice.sh` automatically invokes `fixAndValidateFiles` at the end of every code step,
which runs:

1. `docker compose run --rm boilerplate rector` (executed twice for convergence)
2. `docker compose run --rm boilerplate composer phpcbf . || true`
3. `docker compose run --rm boilerplate composer test:static`
4. `docker compose run --rm boilerplate composer test:unit`

---

## 2. Verifying the generated microservice (`./app`)

When `./app` has already been generated, you can run any Composer or Codeception check inside the `boilerplate` Docker
container without re-running the entire provisioning script.

Use the root `Makefile` targets (which automatically inject `HOST_USER`, `HOST_GROUP`, `HOST_UID`, and `HOST_GID`):

```bash
# Run all tests (static, unit, and integration)
make test

# Run full static analysis suite
make static

# Run Codeception Unit and Functional suites
make unit

# Run integration test script placeholder
make integration
```

Or pass the `HOST_*` environment variables required by `compose.yaml` directly to `docker compose`:

```bash
# Run full static analysis suite
HOST_USER="$(id -un)" HOST_GROUP="$(id -gn)" HOST_UID="$(id -u)" HOST_GID="$(id -g)" \
    docker compose run --rm boilerplate composer test:static

# Run Codeception Unit and Functional suites
HOST_USER="$(id -un)" HOST_GROUP="$(id -gn)" HOST_UID="$(id -u)" HOST_GID="$(id -g)" \
    docker compose run --rm boilerplate composer test:unit

# Run integration test script placeholder
HOST_USER="$(id -un)" HOST_GROUP="$(id -gn)" HOST_UID="$(id -u)" HOST_GID="$(id -g)" \
    docker compose run --rm boilerplate composer test:integration
```

### What `composer test:static` validates in `./app`

1. `@composer validate` — validates `composer.json` schema and lock file synchronization.
2. `@composer normalize --dry-run` — verifies `composer.json` is normalized via `ergebnis/composer-normalize`.
3. `@syntax .` — runs `parallel-lint` across all PHP files (excluding `bin`, `vendor`, `var`).
4. `bin/console lint:container` — verifies Symfony dependency injection container compilation and service wiring.
5. `bin/console lint:yaml config src tests` — validates YAML syntax across `config/`, `src/`, and `tests/`.
6. `@phpcs .` — checks coding style against `ruleset.xml` (`roslov/psr12ext`).
7. `codecept build` — builds Codeception actor classes (`UnitTester`, `FunctionalTester`).
8. `@phpstan` — runs PHPStan at `level: max` with `phpstan/phpstan-symfony` and `stubs/CodeceptionExample.stub`.
9. `rector --dry-run` — verifies no pending Rector refactoring changes remain.

---

## 3. Codeception test suites in `steps/step0050/`

The boilerplate configures Codeception 5.3 with two suites in the generated microservice:

```text
app/tests/
├── Functional/
│   └── ExampleCest.php      # Functional Cest using FunctionalTester (Symfony + Asserts modules)
├── Functional.suite.yml
├── Support/
│   ├── FunctionalTester.php
│   └── UnitTester.php
├── Unit/
│   └── ExampleTest.php      # Unit test extending Codeception\Test\Unit
├── Unit.suite.yml
└── bootstrap.php
```

Note that `Acceptance.suite.yml`, `AcceptanceTester.php`, and `codeception/module-phpbrowser` are intentionally removed
during `step0050` configuration because backend microservices use `Unit` and `Functional` (or `Api`) suites.
