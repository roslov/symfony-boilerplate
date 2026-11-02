# Acceptance Criteria

## Configuration and Environment

- [x] All configuration placeholders, environment variables, and connections are documented in `docs/requirements.md`.
- [x] `.env` and `.env.test` are maintained, accurate, and contain safe development defaults with zero secrets.
- [x] Sensitive parameters (`APP_SECRET`, `RABBITMQ_URL`) are never committed with real production credentials.
- [x] Host and WSL installation prohibitions are documented and enforced across all project workflows.

## Application Setup and Container Startup

- [x] The `${PROJECT_NAME}` container builds and launches cleanly via `make build` and `make up`.
- [x] Dependencies install cleanly inside Docker via `composer install`.
- [x] Runtime permissions in `/app/var` and `/app/var/log` are maintained and writable.

## Queue Consumer & Asynchronous Messaging

- [x] `bin/console rabbitmq:multiple-consumer common -vv` listens to configured queues on the `common` topic exchange.
- [x] `App\Consumer\ExampleConsumer` is registered on queue `${PROJECT_NAME}-some-example` with routing key
      `some-example`.
- [x] Consumers deserialize incoming payloads via `MessagePayloadSerializer` and return `ConsumerInterface::MSG_ACK`.
- [x] `roslov_queue.yaml` configures `service_name`, `ssl_enabled`, `event_processor`, and `exception_subscriber`.

## Security & Reliability

- [x] Container processes execute within isolated Docker boundaries without host/WSL dependency installations.
- [x] RabbitMQ connections support TLS/SSL toggling via `RABBITMQ_SSL_ENABLED` and
      `roslov_queue.rabbitmq.simple_ssl_context_provider`.
- [x] Local logs rotate cleanly (`max_files: 10`), and production logs output JSON with exception stack traces on
      `stderr` at `info` action level.

## Static Analysis, Quality Checks & Testing

- [x] Full static analysis passes cleanly via `composer test:static` (`composer validate`,
      `composer normalize --dry-run`, `parallel-lint`, `lint:container`, `lint:yaml`, `phpcs`, `codecept build`,
      `phpstan` at `level: max`, and `rector --dry-run`).
- [x] Coding style adheres strictly to `ruleset.xml` (`roslov/psr12ext`) via `composer phpcs .`.
- [x] Unit and Functional test suites pass cleanly via `composer test:unit`.
- [x] Integration test suite executes without errors via `composer test:integration`.
- [x] All PHP files enforce strict types (`declare(strict_types=1);`) and detailed PHPDoc doc blocks.
- [x] All Markdown documentation files (`*.md`) strictly adhere to the 120-character line length limit.
- [x] Workspace skills under `.agents/skills/` reflect current project architecture and workflows.
