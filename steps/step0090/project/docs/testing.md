# Testing Strategy and Guide

## Overview

Testing in **${PROJECT_FULL_NAME}** (`${PROJECT_NAME}`) ensures that all queue consumers, domain services, and Symfony
container configurations operate reliably without regressions.

The testing framework is built on [Codeception](http://codeception.com/) using two distinct test suites:

- `Unit`: Isolated unit tests validating consumers, producers, commands, and domain services with mocked dependencies.
- `Functional`: Integration tests evaluating service wiring and component integration against the Symfony test kernel.

---

## Test directory structure

```text
tests/
├── Functional/          # Functional Cest tests validating Symfony container integration
│   └── ExampleCest.php  # Example functional Cest test
├── Functional.suite.yml # Codeception configuration for Functional suite (Symfony + Asserts)
├── Support/             # Codeception actor classes and generated helpers
│   ├── FunctionalTester.php
│   └── UnitTester.php
├── Unit/                # Isolated unit tests extending Codeception\Test\Unit
│   └── ExampleTest.php  # Example unit test
├── Unit.suite.yml       # Codeception configuration for Unit suite (Asserts)
└── bootstrap.php        # Test environment bootstrapping script
```

---

## Writing unit tests (`tests/Unit`)

Unit tests validate isolated PHP classes without accessing external networks, databases, or live RabbitMQ brokers.

### 1. Requirements

- When a new consumer, producer, command, or service class is created, it must be covered by unit tests.
- When an existing class is updated, its unit tests must be updated accordingly.
- External dependencies (such as `LoggerInterface`, `MessagePayloadSerializer`, or queue producers) must be mocked or
  stubbed.
- Test both successful execution paths and error/edge-case scenarios.

### 2. Creating a new unit test

Generate a new unit test class using the Codeception generator:

```bash
codecept g:test Unit Consumer/ExampleConsumerTest
```

Or write a standard test case extending `Codeception\Test\Unit`:

```php
<?php

declare(strict_types=1);

namespace Tests\Unit\Consumer;

use App\Consumer\ExampleConsumer;
use Codeception\Test\Unit;
use OldSound\RabbitMqBundle\RabbitMq\ConsumerInterface;
use PhpAmqpLib\Message\AMQPMessage;
use Psr\Log\LoggerInterface;
use Roslov\QueueBundle\Dto\Trigger;
use Roslov\QueueBundle\Serializer\MessagePayloadSerializer;

final class ExampleConsumerTest extends Unit
{
    public function testExecuteAcknowledgesMessage(): void
    {
        $logger = $this->createMock(LoggerInterface::class);
        $serializer = $this->createMock(MessagePayloadSerializer::class);
        $serializer->method('deserialize')->willReturn(new Trigger());

        $consumer = new ExampleConsumer($logger, $serializer);
        $result = $consumer->execute(new AMQPMessage('{}'));

        $this->assertSame(ConsumerInterface::MSG_ACK, $result);
    }
}
```

---

## Writing functional tests (`tests/Functional`)

Functional tests validate component integration against the initialized Symfony test container (`environment: 'test'`).

### 1. Requirements

- Use functional tests to confirm that services and commands are registered and wired properly in the Symfony DI
  container.
- Assert expected outcomes using `FunctionalTester` (`$I`).

### 2. Creating a new functional test

Generate a functional Cest test using Codeception:

```bash
codecept g:cest Functional ExampleCest
```

---

## Running verification commands

All test and verification commands must be executed within Docker containers:

```bash
# Run full project validation from host (static analysis, unit, and integration tests)
make validate

# Or run individual Composer verification suites inside the container:
docker compose exec ${PROJECT_NAME} composer test:static
docker compose exec ${PROJECT_NAME} composer test:unit
docker compose exec ${PROJECT_NAME} composer test:integration

# Run specific Codeception suites or test files:
docker compose exec ${PROJECT_NAME} codecept run Unit
docker compose exec ${PROJECT_NAME} codecept run Functional
```

---

## Code coverage

To collect code coverage reports, enable XDebug in development:

```bash
make enable-xdebug
docker compose exec ${PROJECT_NAME} bash -c \
    "XDEBUG_MODE=coverage codecept run --coverage --coverage-html --coverage-xml"
```

HTML and XML coverage reports are generated under `tests/_output/`.
