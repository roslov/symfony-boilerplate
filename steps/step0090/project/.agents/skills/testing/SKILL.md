---
name: testing
description: >-
  Implement, expand, and execute Unit and Functional tests with Codeception in accordance with
  repository standards in the ${PROJECT_FULL_NAME} (${PROJECT_NAME}) service. Use when writing
  unit or functional tests, verifying consumers/commands/services, or updating test configurations.
---

# Testing Workflow

This skill guides the implementation, expansion, and execution of `Unit` and `Functional` tests using Codeception in
**${PROJECT_FULL_NAME}** (`${PROJECT_NAME}`).

## Testing Architecture & Conventions

Tests are built using [Codeception](http://codeception.com/) and organized under `tests/`:

1. **`tests/Unit` (`Unit.suite.yml`)**:
   - Isolated unit tests extending `Codeception\Test\Unit`.
   - Validates consumers, producers, commands, and domain services in isolation.
   - External dependencies (such as `LoggerInterface`, `MessagePayloadSerializer`, `ProducerFacade`, HTTP clients, or
     brokers) must be mocked or stubbed.
2. **`tests/Functional` (`Functional.suite.yml`)**:
   - Integration Cest tests using `Tests\Support\FunctionalTester` (`Symfony` and `Asserts` modules).
   - Evaluates service container wiring, console command registration, and component integration in the `test`
     environment.
3. **PHPStan Compatibility (`stubs/CodeceptionExample.stub`)**:
   - `phpstan.dist.neon` runs at `level: max` and includes `stubs/CodeceptionExample.stub` for generic
     `Codeception\Example` type support.
   - `tests/Support/_generated/` is excluded from PHPCS, PHPStan, and Rector.

---

## Step-by-Step Guide: Writing Unit Tests (`tests/Unit/`)

Whenever a new class (consumer, producer, command, or service) is added or modified:

1. Create a test class under `tests/Unit/` mirroring the `src/` namespace (e.g.,
   `tests/Unit/Consumer/ExampleConsumerTest.php` in namespace `Tests\Unit\Consumer`).
2. Declare `declare(strict_types=1);` and include complete PHPDoc doc blocks on the class and all test methods.
3. Extend `Codeception\Test\Unit` and mark the test class `final`.
4. Create mocks/stubs for dependencies (`$this->createMock(...)` or `$this->createStub(...)`).
5. Assert both normal execution paths and edge/error branches.

### Example Unit Test

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

/**
 * Tests example queue consumer execution.
 */
final class ExampleConsumerTest extends Unit
{
    /**
     * Tests that consumer deserializes the message and returns MSG_ACK.
     */
    public function testExecuteAcknowledgesMessage(): void
    {
        $logger = $this->createMock(LoggerInterface::class);
        $logger->expects($this->exactly(2))->method('info');

        $serializer = $this->createStub(MessagePayloadSerializer::class);
        $serializer->method('deserialize')->willReturn(new Trigger());

        $consumer = new ExampleConsumer($logger, $serializer);
        $result = $consumer->execute(new AMQPMessage('{}'));

        $this->assertSame(ConsumerInterface::MSG_ACK, $result);
    }
}
```

---

## Step-by-Step Guide: Writing Functional Tests (`tests/Functional/`)

1. Create a Cest class under `tests/Functional/` (e.g., `tests/Functional/ExampleCest.php` in namespace
   `Tests\Functional`).
2. Declare `declare(strict_types=1);`, mark the class `final`, and add PHPDoc doc blocks on the class and methods.
3. Inject `Tests\Support\FunctionalTester $I` into each test method.
4. Use `$I->grabService(...)` to retrieve services from the Symfony test container and assert behavior.

### Example Functional Test

```php
<?php

declare(strict_types=1);

namespace Tests\Functional;

use Tests\Support\FunctionalTester;

/**
 * Example of a functional test.
 */
final class ExampleCest
{
    /**
     * Executes before a test.
     *
     * @param FunctionalTester $I Tester
     */
    public function _before(FunctionalTester $I): void
    {
        $I->wantTo('do something');
    }

    /**
     * Example test.
     *
     * @param FunctionalTester $I Tester
     */
    public function checkSimpleCase(FunctionalTester $I): void
    {
        /** @phpstan-ignore-next-line */
        $I->assertTrue(true);
    }
}
```

---

## Running Test Commands (Docker Only)

Always execute test commands inside the `${PROJECT_NAME}` Docker container:

```bash
# Run all unit and functional tests
docker compose exec ${PROJECT_NAME} composer test:unit

# Run integration tests
docker compose exec ${PROJECT_NAME} composer test:integration

# Run full project validation (static analysis, unit, and integration tests)
make validate

# Run individual Codeception suites
docker compose exec ${PROJECT_NAME} codecept run Unit
docker compose exec ${PROJECT_NAME} codecept run Functional
```

---

## Skill Maintenance & Self-Enforcement

Whenever changing test suites, Codeception configurations, PHPStan test stubs, or testing workflows, update this skill
file (`.agents/skills/testing/SKILL.md`) to maintain complete alignment.
