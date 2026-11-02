# AGENTS.md

## Purpose

This repository contains the **${PROJECT_FULL_NAME}** (`${PROJECT_NAME}`) microservice for ${PARENT_PROJECT_FULL_NAME},
built with PHP 8.5, Symfony ${SYMFONY_VERSION}, and Roslov Queue Bundle (`roslov/queue-bundle`).

${PROJECT_DESCRIPTION}

This file is mandatory guidance for all automated agents and human contributors.

## Required reading

Before changing code, read:

- `README.md`
- `docs/requirements.md`
- `docs/architecture.md`
- `docs/security.md`
- `docs/testing.md`
- `docs/acceptance-criteria.md`

## Scope discipline

- Implement only the requested task.
- Do not silently resolve product ambiguity with a broad assumption.
- Record a material unresolved decision in the task report.
- Keep pull requests narrow and reviewable.
- Do not mix unrelated refactoring with functional changes.
- Do not upgrade dependencies during unrelated work.
- Preserve `composer.lock`.
- Do not modify `Dockerfile` or files under `.docker/` unless strictly requested.
- Agents are not allowed to install anything on the host machine or WSL and must use Docker containers only.
- Never commit or push changes to git without an explicit user request.

## Architectural boundaries

Application source code and configurations are organized as follows:

- `src/Consumer`: RabbitMQ queue message consumers implementing `OldSound\RabbitMqBundle\RabbitMq\ConsumerInterface`
  (e.g., `ExampleConsumer`).
- `src/Controller`: HTTP request handlers (reserved for health probes, webhooks, or endpoints when needed).
- `src/Kernel.php`: Symfony microkernel configuration and bundle initializations.
- `config/`: Symfony service definitions (`services.yaml`), logging handlers (`packages/monolog.yaml`), and RabbitMQ /
  queue bundle settings (`packages/old_sound_rabbit_mq.yaml`, `packages/roslov_queue.yaml`).
- `stubs/`: PHPStan stub files (`stubs/CodeceptionExample.stub`) for static analysis at `level: max`.
- `tests/`: Codeception test suites (`Unit` and `Functional`).

## Queue and messaging rules

- Queue consumers must implement `OldSound\RabbitMqBundle\RabbitMq\ConsumerInterface`.
- Register consumers in `config/packages/old_sound_rabbit_mq.yaml` under `multiple_consumers.common` with explicit
  queue names (`${PROJECT_NAME}-<event>`), routing keys, and consumer callbacks.
- Deserialize incoming message bodies using `Roslov\QueueBundle\Serializer\MessagePayloadSerializer` into DTOs mapped
  with the `#[AsQueuePayload]` attribute.
- Always acknowledge handled messages by returning `ConsumerInterface::MSG_ACK`.
- Message producers (when added under `src/Producer/`) must extend `Roslov\QueueBundle\Producer\BaseProducer` and be
  centralized in `App\Producer\ProducerFacade` extending `Roslov\QueueBundle\Producer\BaseProducerFacade`.
- Format all AMQP routing keys in lowercase kebab-case (e.g., `some-example`).
- Maintain environment variables `SERVICE_NAME`, `RABBITMQ_URL`, and `RABBITMQ_SSL_ENABLED` across `.env` and
  `.env.test`.

## Testing rules

Every behavioral change requires relevant tests.

### 1. Unit Tests (`tests/Unit`)

- When a new consumer, producer, command, or service class is created, it must be completely covered by unit tests.
- When an existing class is updated, its unit tests must be updated to reflect the change.
- Unit tests must not access external networks, databases, or live RabbitMQ brokers; all dependencies must be mocked or
  stubbed.
- Test both successful execution paths and error/edge-case branches.

### 2. Functional Tests (`tests/Functional`)

- Use functional tests to evaluate service wiring, console command execution, and component integration within the
  Symfony kernel test container (`FunctionalTester`).

## Required commands

All verification commands must be run within the Docker container (e.g., `docker compose exec ${PROJECT_NAME} <cmd>`)
or via `make validate` from the project root. Agents are not allowed to install anything on the host machine or WSL.

Before completion, run:

```bash
composer test:static
composer test:unit
composer test:integration
```

If a command cannot run, report the exact blocker. Do not represent an unexecuted check as passing.

## Code documentation rules

- All classes, interfaces, traits, methods, properties, and constants must have detailed PHPDoc doc blocks.
- Doc blocks must clearly describe purpose, `@param`, `@return`, `@throws`, and `@inheritDoc` where applicable.
- Maintain strict type declarations (`declare(strict_types=1);`) in all PHP source and test files.
- Follow `PSR12Ext` (`roslov/psr12ext`) coding standards configured in `ruleset.xml`.

## Documentation requirements

Update `README.md` and `docs/` when changing:

- RabbitMQ consumers, producers, queues, routing keys, or message schemas;
- Symfony console commands, controllers, or domain services;
- environment variables or configuration baselines (`.env`, `.env.test`);
- build, test, Docker, or CI/CD workflows.

All Markdown documentation files (`*.md`) must strictly adhere to the 120-character line length limit.

## Skill maintenance rules

Whenever changing functionality or workflows, update the corresponding workspace skill under `.agents/skills/`:

- Docker container workflows, verification commands, or static analysis ->
  `.agents/skills/docker-verification/SKILL.md`
- Test suites, testing rules, or Codeception test creation ->
  `.agents/skills/testing/SKILL.md`
- RabbitMQ consumers, producers, routing keys, exchange settings, and message payloads ->
  `.agents/skills/queue-and-messaging/SKILL.md`

## Definition of done

Work is complete only when:

- the requested behavior is implemented;
- all classes, methods, properties, and constants have detailed PHPDoc doc blocks;
- strict types (`declare(strict_types=1);`) are declared in all PHP files;
- `.env` and `.env.test` are maintained, accurate, and contain safe development defaults with zero secrets;
- no software, tools, or dependencies were installed on the host machine or WSL, and all execution occurred strictly
  inside Docker containers;
- `Dockerfile` and files under `.docker/` remain untouched unless strictly requested;
- acceptance criteria in `docs/acceptance-criteria.md` are satisfied;
- tests are added for success and failure paths in compliance with testing rules;
- required verification commands pass (`composer test:static`, `composer test:unit`, `composer test:integration`);
- `README.md` and `docs/` describe the resulting behavior;
- relevant workspace skills under `.agents/skills/` are updated to reflect the resulting behavior;
- all Markdown files strictly adhere to the 120-character line length limit;
- no git commits or pushes are made without an explicit user request;
- the final report lists changed files, checks run, and remaining risks.
