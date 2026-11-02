# Architecture

## Overview

The **Symfony Microservice Boilerplate** is a step-driven project scaffolding system built with Bash, Docker Compose,
PHP 8.5, and Composer. It constructs a new Symfony microservice inside the `./app` directory by running Composer, static
analysis, and automated code transformations inside a dedicated `boilerplate` container while committing each milestone
to Git on the host.

## Runtime contexts

| Context                | Execution Location                | Primary Responsibility                                 |
|------------------------|-----------------------------------|--------------------------------------------------------|
| Orchestrator & Make    | Host (`./create-microservice.sh`) | Cleans `app/`, builds image, applies `steps/`, commits |
| Boilerplate Container  | Docker (`boilerplate`)            | Runs `composer`, `php`, `rector`, `phpcs`, `phpstan`   |
| Generated Microservice | `./app` (`/app` in Docker)        | Output Symfony repo with `main` and `[init]` commits   |

## Repository layout

```text
symfony-boilerplate/
├── .env.dist                # Default template variables for microservice generation
├── .gitignore               # Ignores /.idea/, /app/, and .env
├── Makefile                 # Host helper targets (build, shell, test, static, unit, integration, help)
├── compose.yaml             # Defines the `boilerplate` Docker Compose service
├── create-microservice.sh   # Main Bash pipeline script
├── docker/
│   ├── Dockerfile           # PHP 8.5 + Composer 2.11 image with UID/GID mapping
│   └── image-files/         # Container filesystem overlay
│       ├── root/.bashrc     # Shell aliases and prompt settings
│       └── usr/local/
│           ├── bin/
│           │   ├── app-bootstrap         # Container CMD entrypoint script
│           │   ├── docker-php-entrypoint # PHP entrypoint wrapper
│           │   └── init-composer         # Helper script for `composer install -n`
│           └── etc/php/conf.d/
│               ├── base-custom.ini       # Base PHP INI settings (UTC, opcache, error reporting)
│               └── custom.ini            # Overrides memory_limit = 512M
└── steps/
    ├── step0010/            # .gitignore IDE additions
    ├── step0020/            # .editorconfig and .gitattributes
    ├── step0030/            # Base README.md template
    ├── step0038/            # Development Makefile template
    ├── step0040/            # PHPCS ruleset.xml (PSR12Ext), coding-style.md, faq.md
    ├── step0045/            # Monolog configuration (monolog.yaml)
    ├── step0050/            # Codeception configuration, tests.md, Unit & Functional tests
    ├── step0060/            # PHPStan stub (CodeceptionExample.stub)
    ├── step0070/            # Queue bundle configs, parameters.yaml, consumers.md, ExampleConsumer.php
    ├── step0080/            # Rector configuration (rector.php)
    ├── step0090/            # AI agent support (AGENTS.md, documentation.md, docs/, .agents/skills/)
    └── step1010/            # Declarative Jenkinsfile CI template
```

## Core orchestration helpers (`create-microservice.sh`)

`create-microservice.sh` defines reusable helper functions used across provisioning stages:

1. **`logStep "<message>"` & `logSubStep "<message>"`**:
   - Format primary stage headers and secondary action logs with consistent ANSI color codes.
2. **`runInContainer <cmd> [args...]`**:
   - Executes commands inside the `boilerplate` Docker container (`docker compose run --rm boilerplate "$@"`).
3. **`requireWithContrib <args...>`**:
   - Temporarily enables `extra.symfony.allow-contrib`, runs `composer require "$@"`, disables `allow-contrib`, and
     runs `composer update --lock`.
4. **`updateComposerJsonWithJq "<filter>"` & `updateComposerJsonWithPhp`**:
   - Modify `composer.json` in place using `jq --indent 4` or a PHP snippet read from standard input operating on
     `$composer`.
5. **`prependToFile`, `renderTemplate`, & `replacePlaceholder`**:
   - Prepend template files, render templates via `envsubst` with an explicit variable whitelist, or inject snippet
     files into `${REPLACE}` placeholders.
6. **`normalizeComposer()`**:
   - Runs `runInContainer composer bump` to pin minimum dependency versions in `composer.json`.
   - Runs `runInContainer composer normalize` to canonicalize `composer.json` structure.
7. **`fixAndValidateFiles()`**:
   - If `vendor/bin/rector` is installed, runs `rector` **twice** inside the container so cascading AST transformations
     settle completely.
   - Runs `composer phpcbf . || true` to auto-format code according to `ruleset.xml`.
   - Runs `composer test:static` to verify `composer validate`, `composer normalize --dry-run`, `parallel-lint`,
     `bin/console lint:container`, `bin/console lint:yaml`, `phpcs`, `codecept build`, `phpstan`, and
     `rector --dry-run`.
   - Runs `composer test:unit` to execute the Codeception test suites.
8. **`commit "<message>"`**:
   - Stages all files (`git add .`) and creates a commit prefixed with `[init] <message>`.

## Provisioning pipeline flow

```text
Host: ./create-microservice.sh
  │
  ├── 1. Load .env.dist and .env
  ├── 2. Recreate ./app directory (rm -rf app && mkdir app)
  ├── 3. Export HOST_USER, HOST_GROUP, HOST_UID, HOST_GID & run `docker compose build`
  ├── 4. cd app && create Symfony skeleton (`composer create-project symfony/skeleton:${SYMFONY_VERSION}.x .`)
  ├── 5. Initialize Git (`git init && git branch -m main`)
  │
  ├── Step 0010: Prepend IDE rules to .gitignore
  ├── Step 0020: Copy .editorconfig and .gitattributes
  ├── Step 0030: Render README.md via envsubst
  ├── Composer:  Configure name/description, require php:>=8.5, replace polyfills, add composer-normalize
  ├── Step 0038: Render Makefile via envsubst
  ├── Step 0040: Install parallel-lint & roslov/psr12ext, copy ruleset.xml, configure Composer scripts
  ├── Base Pkgs: Install monolog-bundle, serializer, debug-bundle
  ├── Step 0045: Configure Monolog rotating_file (dev/test), info level & JSON stack traces (prod)
  ├── Step 0050: Install & configure Codeception 5.3 (Unit & Functional suites, ExampleTest, ExampleCest)
  ├── Step 0060: Install phpstan/phpstan-symfony, set level: max, add stubs/CodeceptionExample.stub
  ├── Step 0070: Install roslov/queue-bundle, configure RabbitMQ & ExampleConsumer
  ├── Step 0080: Install rector/rector and apply steps/step0080/rector.php
  ├── Step 0090: Render AGENTS.md, docs/*.md, .agents/skills/*/SKILL.md, and update README.md
  └── Step 1010: Render Jenkinsfile via envsubst
```

## Generated microservice architecture (`app/`)

Once `./create-microservice.sh` finishes, `./app` contains a self-contained Symfony microservice layout:

```text
app/
├── .agents/
│   └── skills/
│       ├── docker-verification/
│       ├── queue-and-messaging/
│       └── testing/
├── .editorconfig
├── .env                     # Default environment variables (APP_ENV, RABBITMQ_URL, SERVICE_NAME)
├── .env.test                # Test environment overrides (test-rabbitmq)
├── .gitattributes
├── .gitignore
├── AGENTS.md                # AI agent and contributor guidance
├── Jenkinsfile              # CI pipeline triggering `pr-check` and `deployment` jobs
├── Makefile                 # Host helper targets delegating to `$(MAKE) -C ../..`
├── README.md                # Generated service documentation
├── bin/console              # Symfony CLI entrypoint
├── codeception.yml          # Codeception master configuration
├── composer.json            # Normalized Composer configuration with quality scripts
├── composer.lock            # Locked dependency tree
├── config/
│   ├── bundles.php
│   ├── packages/
│   │   ├── monolog.yaml
│   │   ├── old_sound_rabbit_mq.yaml
│   │   └── roslov_queue.yaml
│   └── services.yaml
├── docs/
│   ├── acceptance-criteria.md
│   ├── architecture.md
│   ├── requirements.md
│   ├── security.md
│   └── testing.md
├── phpstan.dist.neon        # PHPStan level: max configuration
├── public/index.php         # HTTP front controller
├── rector.php               # Rector configuration
├── ruleset.xml              # PHP_CodeSniffer PSR12Ext standard configuration
├── src/
│   ├── Consumer/
│   │   └── ExampleConsumer.php
│   ├── Controller/
│   └── Kernel.php
├── stubs/
│   └── CodeceptionExample.stub
└── tests/
    ├── Functional/
    │   └── ExampleCest.php
    ├── Functional.suite.yml
    ├── Support/
    ├── Unit/
    │   └── ExampleTest.php
    ├── Unit.suite.yml
    └── bootstrap.php
```
