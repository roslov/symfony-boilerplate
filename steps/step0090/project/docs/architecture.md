# Architecture

## Overview

**${PROJECT_FULL_NAME}** (`${PROJECT_NAME}`) is an event-driven microservice built on PHP 8.5, Symfony
${SYMFONY_VERSION}, and Roslov Queue Bundle (`roslov/queue-bundle`). It operates within the
${PARENT_PROJECT_FULL_NAME} ecosystem and communicates asynchronously over RabbitMQ (`common` topic exchange).

## Runtime contexts

| Context              | Container Service | Primary Responsibility                                                |
|----------------------|-------------------|-----------------------------------------------------------------------|
| Microservice Runtime | `${PROJECT_NAME}` | Executes Symfony CLI commands, queue consumers, and domain services   |
| Message Broker       | `rabbitmq`        | AMQP broker routing domain events and tasks via the `common` exchange |

## Layer responsibilities

```text
src/
├── Consumer/            # RabbitMQ queue message consumers (e.g., ExampleConsumer)
├── Controller/          # HTTP request handlers (reserved for health probes or endpoints)
└── Kernel.php           # Symfony microkernel configuration and bundle initializations
config/
├── bundles.php          # Enabled Symfony bundles list
├── packages/            # Package configurations (monolog, old_sound_rabbit_mq, roslov_queue)
├── routes.yaml          # Route definitions
└── services.yaml        # Service container dependency injection definitions and parameters
stubs/
└── CodeceptionExample.stub # PHPStan level: max generic stub for Codeception\Example
tests/
├── Functional/          # Functional integration tests evaluating the Symfony container
├── Support/             # Codeception actor classes (UnitTester, FunctionalTester)
└── Unit/                # Isolated unit tests covering domain services and consumers
```

### 1. Consumer Layer (`src/Consumer`)

- Implements `OldSound\RabbitMqBundle\RabbitMq\ConsumerInterface`.
- Registered in `config/packages/old_sound_rabbit_mq.yaml` under `multiple_consumers.common` bound to the `common`
  topic exchange.
- Deserializes JSON message payloads using `Roslov\QueueBundle\Serializer\MessagePayloadSerializer` into DTOs mapped
  via the `#[AsQueuePayload]` attribute.
- Logs processing lifecycle events via `Psr\Log\LoggerInterface` and returns `ConsumerInterface::MSG_ACK`.

### 2. Logging & Observability (`config/packages/monolog.yaml`)

- **Development & Test (`when@dev`, `when@test`)**: Uses `rotating_file` handlers writing to
  `%kernel.logs_dir%/%kernel.environment%.log` with a retention limit of 10 files (`max_files: 10`).
- **Production (`when@prod`)**: Uses a `fingers_crossed` handler at `action_level: info` streaming to `php://stderr`
  formatted as JSON with full exception stack traces via `app.monolog.json_formatter_with_trace`.

### 3. Message Ingestion Lifecycle

```text
AMQP Message Arrives (Exchange: 'common', Routing Key: 'some-example')
  │
  ▼
bin/console rabbitmq:multiple-consumer common -vv
  │
  ▼
ExampleConsumer::execute(AMQPMessage $msg)
  │
  ├── 1. Deserialize message payload via MessagePayloadSerializer::deserialize()
  ├── 2. Log consumer execution start
  ├── 3. Execute domain business logic
  ├── 4. Log consumer execution completion
  │
  ▼
Return ConsumerInterface::MSG_ACK
```
