# Product Requirements

## Product summary

The **Symfony Microservice Boilerplate** is the standardized project generator for creating new PHP microservices based
on the Symfony framework. Rather than copying an existing service and manually stripping domain logic, developers run
`./create-microservice.sh` to construct a fresh microservice repository inside `./app` with a complete, granular history
of `[init]` Git commits.

Each generated microservice comes preconfigured with PHP 8.5, Symfony (`symfony/skeleton`), Monolog, Symfony Serializer,
Roslov Queue Bundle (`roslov/queue-bundle`), RabbitMQ (`php-amqplib/rabbitmq-bundle`), Codeception (`Unit` and
`Functional` suites), PHP_CodeSniffer (`roslov/psr12ext`), PHPStan (`level: max`), Rector,
`ergebnis/composer-normalize`, AI agent guidance (`AGENTS.md`, `docs/`, and `.agents/skills/`), a host development
`Makefile`, and a declarative `Jenkinsfile`.

## Configuration placeholders

### 1. Generator environment variables (`.env.dist` / `.env`)

| Variable                   | Default / Example Value      | Purpose                                                  |
|----------------------------|------------------------------|----------------------------------------------------------|
| `SYMFONY_VERSION`          | `8.1`                        | Target Symfony major.minor skeleton branch (`8.1.x`)     |
| `REPO_SITE`                | `github.com`                 | Git hosting domain interpolated into `README.md` links   |
| `VENDOR`                   | `yourvendor`                 | Composer vendor namespace (`<vendor>/<project_name>`)    |
| `PROJECT_NAME`             | `example`                    | Short service identifier (`composer.json`, queues, CI)   |
| `PROJECT_FULL_NAME`        | `"Microservice Example"`     | Full project title (`README.md` heading & Composer desc) |
| `PROJECT_DESCRIPTION`      | Multiline description string | Detailed overview rendered into generated `README.md`    |
| `PARENT_PROJECT_FULL_NAME` | `"Global Project Example"`   | Ecosystem name referenced in generated `README.md`       |

### 2. Docker build arguments (`docker/Dockerfile` & `compose.yaml`)

| Argument / Variable | Default Value | Purpose                                                                  |
|---------------------|---------------|--------------------------------------------------------------------------|
| `IMAGE_TAG`         | `8.5.12`      | Base `php:$IMAGE_TAG` CLI image tag                                      |
| `COMPOSER_VERSION`  | `2.11.1`      | Base `composer:$COMPOSER_VERSION` image used to copy `/usr/bin/composer` |
| `HOST_USER`         | `$(id -un)`   | Host username created inside the container                               |
| `HOST_GROUP`        | `$(id -gn)`   | Host group name created inside the container                             |
| `HOST_UID`          | `$(id -u)`    | Host user UID assigned to container user and `/app` directory            |
| `HOST_GID`          | `$(id -g)`    | Host group GID assigned to container group and `/app` directory          |

### 3. Generated microservice runtime variables (`app/.env` & `app/.env.test`)

| Variable               | Generated Default (`.env`)             | Generated Test Default (`.env.test`)        |
|------------------------|----------------------------------------|---------------------------------------------|
| `APP_ENV`              | `dev`                                  | `test`                                      |
| `APP_SECRET`           | Generated 32-char hex string           | `$ecretf0rt3st`                             |
| `SERVICE_NAME`         | `${PROJECT_NAME}`                      | Inherited from `.env`                       |
| `RABBITMQ_URL`         | `amqp://guest:guest@rabbitmq:5672`     | `amqp://guest:guest@test-rabbitmq:5672`     |
| `RABBITMQ_SSL_ENABLED` | `false`                                | Inherited from `.env`                       |

## Bootstrapping pipeline specification

Executing `./create-microservice.sh` must perform the following 19 sequential stages and commit each stage to the `main`
branch in `app/`:

1. **Symfony Skeleton (`[init] Installed Symfony skeleton v${SYMFONY_VERSION}`)**:
   - Installs `symfony/skeleton:"${SYMFONY_VERSION}.x"` into `app/` and initializes a Git repository on branch `main`.
2. **Git Ignore (`[init] Updated .gitignore`)**:
   - Prepends `steps/step0010/.gitignore` (`/.idea/`, `/.vscode/`, `*.code-workspace`) to the project `.gitignore`.
3. **Editor & Git Attributes (`[init] Added .editorconfig and .gitattributes`)**:
   - Copies `.editorconfig` and `.gitattributes` from `steps/step0020/`.
4. **Documentation (`[init] Added README.md`)**:
   - Renders `steps/step0030/README.md` using `envsubst` with project variables and dynamic `=` underline header.
5. **Composer Metadata & PHP 8.5 (`[init] Updated composer.json`)**:
   - Sets package `name` (`${VENDOR}/${PROJECT_NAME}`) and `description` (`${PROJECT_FULL_NAME}`), places them at the
     top of `composer.json` via `jq`, requires `php:>=8.5`, adds `symfony/polyfill-php83`, `84`, and `85` replacements,
     and installs `ergebnis/composer-normalize`.
6. **Makefile (`[init] Added Makefile`)**:
   - Renders `steps/step0038/Makefile` with `${PROJECT_NAME}` providing `up`, `down`, `build`, `shell`, `validate`,
     `enable-xdebug`, `disable-xdebug`, and `help` targets.
7. **CodeSniffer & Syntax Linting (`[init] Added CodeSniffer with PSR-12 Ext rules. Added syntax validation`)**:
   - Installs `php-parallel-lint/php-console-highlighter`, `php-parallel-lint/php-parallel-lint`, and `roslov/psr12ext`.
   - Configures Composer scripts (`phpcs`, `phpcbf`, `syntax`, `test`, `test:static`, `test:unit`, `test:integration`).
   - Copies `steps/step0040/ruleset.xml`, updates `README.md` with `coding-style.md` and `faq.md`.
8. **Base Packages (`[init] Installed base packages`)**:
   - Requires `symfony/monolog-bundle`, `symfony/serializer`, and dev dependency `symfony/debug-bundle`.
9. **Log Rotation (`[init] Added log file rotation for local environment`)**:
   - Replaces `config/packages/monolog.yaml` with `steps/step0045/monolog.yaml` (`rotating_file`, `max_files: 10`).
10. **Production Log Level (`[init] Decreased log level from error to info for production`)**:
    - Updates `action_level` in `when@prod` handler from `error` to `info`.
11. **Production Log Stack Traces (`[init] Added exception stack trace for production logs`)**:
    - Registers `app.monolog.json_formatter_with_trace` (`Monolog\Formatter\JsonFormatter` with
      `$includeStacktraces: true`) in `config/services.yaml` and wires it into `config/packages/monolog.yaml`.
12. **Codeception Bootstrap (`[init] Tests: Installed and bootstrapped Codeception v5.3 ...`)**:
    - Installs `codeception/codeception:^5.3`, `codeception/module-asserts`, `codeception/module-symfony`, and
      `codeception/module-phpbrowser`, and runs `codecept bootstrap` (committed with message
      `[init] Tests: Installed and bootstrapped Codeception v5.3 with modules Asserts, PhpBrowser and Symfony`).
13. **Codeception Configuration (`[init] Tests: Configured Codeception`)**:
    - Updates `README.md` with `steps/step0050/tests.md`, appends coverage settings from
      `steps/step0050/codeception.yml`, sets `Tests\` autoloading in `composer.json`, removes
      `codeception/module-phpbrowser` and the `Acceptance` suite, configures `Functional.suite.yml` with `Symfony` and
      `Asserts` modules, updates `ruleset.xml` for `tests/`, and copies `ExampleTest.php` and `ExampleCest.php`.
14. **PHPStan (`[init] Added PHPStan`)**:
    - Installs `phpstan/phpstan-symfony`, configures `phpstan.dist.neon` at `level: max` with
      `stubs/CodeceptionExample.stub` from `steps/step0060/stubs`, updates `public/index.php` return type, and adds
      `codecept build` and `@phpstan` to `test:static`.
15. **Queue Bundle (`[init] Set up Queue bundle and added consumer stub`)**:
    - Installs `roslov/queue-bundle`, configures `RABBITMQ_URL`, `SERVICE_NAME`, and `RABBITMQ_SSL_ENABLED` in `.env`
      and `.env.test`, updates `README.md` with `consumers.md`, injects parameters into `config/services.yaml`, and
      copies `roslov_queue.yaml`, `old_sound_rabbit_mq.yaml`, and `src/Consumer/ExampleConsumer.php` from
      `steps/step0070/`.
16. **Rector Installation (`[init] Added Rector`)**:
    - Installs `rector/rector`, initializes default Rector config, and adds `rector --dry-run` to `test:static`.
17. **Rector Configuration (`[init] Configured Rector`)**:
    - Copies `steps/step0080/rector.php` and runs `fixAndValidateFiles`.
18. **AI Agent Support (`[init] Added AI agent support`)**:
    - Updates `README.md` with `steps/step0090/documentation.md`, copies `AGENTS.md`, `docs/*.md`, and
      `.agents/skills/*/SKILL.md` from `steps/step0090/project/`, renders project variables via `envsubst`, and runs
      `fixAndValidateFiles`.
19. **CI Configuration (`[init] CI: Added Jenkinsfile`)**:
    - Renders `steps/step1010/Jenkinsfile` with `${PROJECT_NAME}`.
