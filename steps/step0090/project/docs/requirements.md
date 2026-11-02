# Product Requirements

## Product summary

**${PROJECT_FULL_NAME}** (`${PROJECT_NAME}`) is a microservice in the ${PARENT_PROJECT_FULL_NAME} ecosystem, built with
PHP 8.5, Symfony ${SYMFONY_VERSION}, and Roslov Queue Bundle (`roslov/queue-bundle`).

${PROJECT_DESCRIPTION}

## Configuration placeholders

| Setting                 | Default / Example Value                 | Environment Variable   |
|-------------------------|-----------------------------------------|------------------------|
| Application environment | `dev` / `prod` / `test`                 | `APP_ENV`              |
| Application secret key  | Random 32-byte secret string            | `APP_SECRET`           |
| Microservice name       | `${PROJECT_NAME}`                       | `SERVICE_NAME`         |
| RabbitMQ connection URL | `amqp://guest:guest@rabbitmq:5672`      | `RABBITMQ_URL`         |
| RabbitMQ SSL toggle     | `false`                                 | `RABBITMQ_SSL_ENABLED` |
| Test RabbitMQ URL       | `amqp://guest:guest@test-rabbitmq:5672` | `RABBITMQ_URL`         |

The repository must always maintain accurate `.env` and `.env.test` files reflecting all configurable parameters with
safe development defaults and zero production secrets.

## Consumer inventory

Background consumers run under the daemon `bin/console rabbitmq:multiple-consumer common -vv`:

### 1. Example Consumer

- **Consumer**: `App\Consumer\ExampleConsumer`
- **AMQP Exchange**: `common` (topic exchange)
- **AMQP Queue**: `${PROJECT_NAME}-some-example`
- **AMQP Routing Key**: `some-example`
- **Purpose**: Reference queue consumer demonstrating message payload deserialization, structured logging, and AMQP
  message acknowledgment (`ConsumerInterface::MSG_ACK`).

## Asynchronous messaging specifications

The microservice relies on `roslov/queue-bundle` and `php-amqplib/rabbitmq-bundle` for asynchronous messaging:

- **Connection**: Managed lazily via `old_sound_rabbit_mq.connections.default` using `RABBITMQ_URL` and SSL context
  provider `roslov_queue.rabbitmq.simple_ssl_context_provider`.
- **Consumers**: Configured under `old_sound_rabbit_mq.multiple_consumers.common` bound to the `common` topic exchange.
- **Event Processor**: Configured in `config/packages/roslov_queue.yaml` with `instant_delivery: true` and disabled in
  the `test` environment (`delayed_delivery_subscriber: false`).
- **Exception Handling**: Unhandled exceptions are published to the `common` topic exchange via `exception_subscriber`
  and `exception_sender` in non-test environments, and logged via Monolog.
