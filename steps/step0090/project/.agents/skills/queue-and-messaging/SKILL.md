---
name: queue-and-messaging
description: >-
  Implement, configure, and test RabbitMQ message consumers, producers, routing keys, and payload
  DTOs using Roslov Queue Bundle in the ${PROJECT_FULL_NAME} (${PROJECT_NAME}) service. Use when
  adding or modifying queue consumers, producers, exchanges, or RabbitMQ settings.
---

# Queue and Messaging Workflow

This skill guides the implementation, configuration, and testing of RabbitMQ message consumers, producers, routing keys,
and payload DTOs using `roslov/queue-bundle` and `php-amqplib/rabbitmq-bundle` in **${PROJECT_FULL_NAME}**
(`${PROJECT_NAME}`).

## Messaging Architecture

1. **Multiple Consumer (`multiple_consumers.common`)**:
   - The background worker runs `bin/console rabbitmq:multiple-consumer common -vv`.
   - Configured in `config/packages/old_sound_rabbit_mq.yaml` bound to the `common` topic exchange.
   - Each queue uses the naming convention `${PROJECT_NAME}-<event>` (e.g., `${PROJECT_NAME}-some-example`) and maps
     one or more lowercase kebab-case `routing_keys` to a consumer `callback`.
2. **Consumer Classes (`src/Consumer/`)**:
   - Implement `OldSound\RabbitMqBundle\RabbitMq\ConsumerInterface`.
   - Implement `execute(AMQPMessage $msg): int` and return `ConsumerInterface::MSG_ACK` when handled.
3. **Payload Deserialization & DTO Mapping**:
   - Uses `Roslov\QueueBundle\Serializer\MessagePayloadSerializer` to deserialize AMQP message JSON bodies.
   - Custom payload DTOs under `src/Dto/Queue/` map their message type using `#[AsQueuePayload('...')]`.
4. **Producers (`src/Producer/`, when publishing events)**:
   - Producer classes extend `Roslov\QueueBundle\Producer\BaseProducer` and define `getRoutingKey(): string`.
   - `App\Producer\ProducerFacade` extends `Roslov\QueueBundle\Producer\BaseProducerFacade` as the unified dispatch
     entrypoint.
5. **Bundle Configuration (`config/packages/roslov_queue.yaml`)**:
   - Configures `service_name: '%env(string:SERVICE_NAME)%'`, `ssl_enabled: '%env(bool:RABBITMQ_SSL_ENABLED)%'`,
     `event_processor`, and `exception_subscriber` / `exception_sender`.

---

## Step-by-Step Guide: Adding a Consumer

### Step 1: Create the Consumer Class (`src/Consumer/`)

Create a `final readonly` class implementing `ConsumerInterface`:

```php
<?php

declare(strict_types=1);

namespace App\Consumer;

use OldSound\RabbitMqBundle\RabbitMq\ConsumerInterface;
use Override;
use PhpAmqpLib\Message\AMQPMessage;
use Psr\Log\LoggerInterface;
use Roslov\QueueBundle\Serializer\MessagePayloadSerializer;

use function assert;

/**
 * Consumer: Handles incoming example events.
 */
final readonly class ExampleConsumer implements ConsumerInterface
{
    /**
     * Constructor.
     *
     * @param LoggerInterface $logger Logger
     * @param MessagePayloadSerializer $serializer Serializer
     */
    public function __construct(
        private LoggerInterface $logger,
        private MessagePayloadSerializer $serializer,
    ) {
    }

    /**
     * @inheritDoc
     */
    #[Override]
    public function execute(AMQPMessage $msg): int
    {
        $dto = $this->serializer->deserialize($msg->getBody());
        /** @phpstan-ignore-next-line */
        assert((bool) $dto);
        $this->logger->info('Example consumer started.');
        // Handle event...
        $this->logger->info('Example consumer completed.');

        return ConsumerInterface::MSG_ACK;
    }
}
```

### Step 2: Register Queue and Callback in `config/packages/old_sound_rabbit_mq.yaml`

Add the queue definition under `old_sound_rabbit_mq.multiple_consumers.common.queues`:

```yaml
old_sound_rabbit_mq:
    multiple_consumers:
        common:
            connection: default
            exchange_options: { name: 'common', type: topic }
            enable_logger: true
            queues:
                some-example:
                    name: ${PROJECT_NAME}-some-example
                    routing_keys:
                        - some-example
                    callback: App\Consumer\ExampleConsumer
```

### Step 3: Map Custom Queue Payload DTOs (Optional)

When consuming a custom payload DTO instead of `Roslov\QueueBundle\Dto\Trigger`, annotate the DTO class with
`#[AsQueuePayload]`:

```php
<?php

declare(strict_types=1);

namespace App\Dto\Queue;

use Roslov\QueueBundle\Attribute\AsQueuePayload;

/**
 * Event DTO: Custom event payload.
 */
#[AsQueuePayload('Event.SomeExample')]
final class SomeExampleDto
{
}
```

---

## Step-by-Step Guide: Adding a Producer

1. Create a producer class in `src/Producer/` extending `Roslov\QueueBundle\Producer\BaseProducer` and implementing
   `protected function getRoutingKey(): string`.
2. Register the producer under `old_sound_rabbit_mq.producers` in `config/packages/old_sound_rabbit_mq.yaml` targeting
   `exchange_options: { name: 'common', type: topic }`.
3. Register or update `App\Producer\ProducerFacade` extending `Roslov\QueueBundle\Producer\BaseProducerFacade` with a
   typed helper method calling `$this->send('<producer_name>', $dto)`.

---

## Verification Commands (Docker Only)

```bash
docker compose exec ${PROJECT_NAME} bin/console lint:yaml config src tests
docker compose exec ${PROJECT_NAME} bin/console lint:container
docker compose exec ${PROJECT_NAME} composer test:static
docker compose exec ${PROJECT_NAME} composer test:unit
```

---

## Skill Maintenance & Self-Enforcement

Whenever changing RabbitMQ connection parameters, exchange topologies, consumer queues, producer facades, or message
schemas, update this skill file (`.agents/skills/queue-and-messaging/SKILL.md`) to reflect current configurations.
