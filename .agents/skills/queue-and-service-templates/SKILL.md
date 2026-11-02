---
name: queue-and-service-templates
description: >-
  Maintain and update the microservice runtime, logging, queue consumer, Makefile, and CI pipeline
  templates (`steps/step0038/Makefile`, `steps/step0045/monolog.yaml`, `steps/step0070` Roslov Queue
  Bundle & RabbitMQ configs, and `steps/step1010/Jenkinsfile`). Use when modifying RabbitMQ/queue
  defaults, Monolog handlers, Makefile targets, or Jenkins CI stages.
---

# Queue and Service Templates Workflow

This skill covers the microservice infrastructure templates applied in `steps/step0038`, `steps/step0045`,
`steps/step0070`, and `steps/step1010`.

## 1. Host Development `Makefile` (`steps/step0038/Makefile`)

- Rendered with `${PROJECT_NAME}` via `envsubst '${PROJECT_NAME}'`.
- Designed to be executed on the host machine inside `deployment/src/<service>/`, delegating commands to the root
  deployment `Makefile` (`MAIN_MAKE := $(MAKE) -C ../..`):
  - `up` / `down`: Starts or stops the development environment (`$(MAIN_MAKE) up` / `down`).
  - `build`: Builds the service container (`$(MAIN_MAKE) build-$(SERVICE)`).
  - `shell`: Opens an interactive shell inside the service container (`$(MAIN_MAKE) shell-$(SERVICE)`).
  - `validate`: Runs static analysis and tests (`$(MAIN_MAKE) validate-$(SERVICE)`).
  - `enable-xdebug` / `disable-xdebug`: Toggles XDebug for the service container.
  - `help`: Parses `##` comments in `Makefile` to print colored usage instructions.

---

## 2. Monolog Configuration (`steps/step0045/monolog.yaml` + `create-microservice.sh`)

`create-microservice.sh` applies three sequential commits for logging:

1. **Local Log Rotation (`step0045/monolog.yaml`)**:
   - Configures `when@dev` (`main` handler) and `when@test` (`nested` handler) with `type: rotating_file`,
     `max_files: 10`, `file_permission: 0777`, and `path: "%kernel.logs_dir%/%kernel.environment%.log"`.
2. **Production Action Level**:
   - Lowers `when@prod.monolog.handlers.main.action_level` from `error` to `info`.
3. **Production Exception Stack Traces**:
   - Registers `app.monolog.json_formatter_with_trace` (`Monolog\Formatter\JsonFormatter` with
     `$includeStacktraces: true`) in `config/services.yaml`.
   - Replaces `formatter: monolog.formatter.json` with `formatter: app.monolog.json_formatter_with_trace` in
     `config/packages/monolog.yaml` so production stderr JSON logs include full exception stack traces.

---

## 3. Roslov Queue Bundle & RabbitMQ (`steps/step0070/`)

`step0070` installs `roslov/queue-bundle` (which brings in `php-amqplib/rabbitmq-bundle`) and sets up asynchronous
AMQP messaging:

1. **Environment Variables (`.env` & `.env.test`)**:
   - `.env`:
     - `RABBITMQ_URL=amqp://guest:guest@rabbitmq:5672`
     - `SERVICE_NAME=${PROJECT_NAME}`
     - `RABBITMQ_SSL_ENABLED=false`
   - `.env.test`:
     - `RABBITMQ_URL=amqp://guest:guest@test-rabbitmq:5672`
2. **Container Parameters (`steps/step0070/parameters.yaml` -> `config/services.yaml`)**:
   - Injects `env(SERVICE_NAME): '%env(string:SERVICE_NAME)%'` and
     `env(RABBITMQ_SSL_ENABLED): '%env(bool:RABBITMQ_SSL_ENABLED)%'` under `parameters:`.
3. **Roslov Queue Configuration (`steps/step0070/project/config/packages/roslov_queue.yaml`)**:
   - Sets `service_name`, `ssl_enabled`, `logger: logger`, `entity_manager: ~`.
   - Enables `event_processor` (`instant_delivery: true`) and `exception_subscriber` with `exchange_options`
     (`{ name: 'common', type: topic }`).
   - Disables `delayed_delivery_subscriber` and `exception_subscriber` in `when@test`.
4. **RabbitMQ Configuration (`steps/step0070/project/config/packages/old_sound_rabbit_mq.yaml`)**:
   - Configures `connections.default` using `%env(RABBITMQ_URL)%`, `lazy: true`, and
     `connection_parameters_provider: roslov_queue.rabbitmq.simple_ssl_context_provider`.
   - Includes a commented `producers:` example (`trigger_some_command`).
   - Configures `multiple_consumers.common` on the `common` topic exchange with queue `${PROJECT_NAME}-some-example`,
     routing key `some-example`, and callback `App\Consumer\ExampleConsumer`.
5. **Consumer Stub (`steps/step0070/project/src/Consumer/ExampleConsumer.php`)**:
   - `final readonly class ExampleConsumer implements ConsumerInterface`.
   - Injects `Psr\Log\LoggerInterface` and `Roslov\QueueBundle\Serializer\MessagePayloadSerializer`.
   - Deserializes `$msg->getBody()`, logs execution start and completion, and returns `ConsumerInterface::MSG_ACK`.

---

## 4. Jenkins CI Pipeline (`steps/step1010/Jenkinsfile`)

- Rendered with `${PROJECT_NAME}` via `envsubst '${PROJECT_NAME}'`.
- Defines two stages with `disableConcurrentBuilds()`:
  - `PR Check` (on `changeRequest()`): Triggers upstream `pr-check` job with `service: '${PROJECT_NAME}'`,
    `sourceBranch`, and `targetBranch`.
  - `Deployment` (on `main` or `develop` branches): Triggers upstream `deployment` job with `service: '${PROJECT_NAME}'`
    and `branch`.

---

## Skill Maintenance & Self-Enforcement

Whenever changing `steps/step0038/Makefile`, `steps/step0045/monolog.yaml`, `steps/step0070/*`, or
`steps/step1010/Jenkinsfile`, update this skill file (`.agents/skills/queue-and-service-templates/SKILL.md`).
