# Security and Privacy

## Security goals

- Protect RabbitMQ credentials, application secrets, and connection URIs against disclosure or unauthorized access.
- Ensure all incoming queue payloads are deserialized into strictly typed DTOs before execution.
- Guard against resource exhaustion, hanging consumer processes, and uncontrolled log growth.
- Ensure strict container isolation without exposing unnecessary network ports or elevated privileges.
- Maintain accurate, zero-secret environment configurations (`.env`, `.env.test`).

## Trust boundaries

The `${PROJECT_NAME}` microservice executes within an isolated internal Docker container network:

- **Host & Container Isolation**: All PHP, Composer, and runtime commands execute inside the `${PROJECT_NAME}` Docker
  container.
- **Message Broker (RabbitMQ)**: Messages are consumed and published over authenticated AMQP connections
  (`RABBITMQ_URL`) with configurable TLS/SSL encryption via `RABBITMQ_SSL_ENABLED=true`.
- **Untrusted Payloads**: Incoming AMQP message payloads and any external inputs must be treated as untrusted until
  deserialized and validated against expected DTO contracts.

## Data classification

| Data Category        | Classification        | Handling & Protection Rules                                  |
|----------------------|-----------------------|--------------------------------------------------------------|
| Application secret   | High-Security Secret  | Set via `APP_SECRET`; never commit production keys to git    |
| RabbitMQ credentials | Infrastructure Secret | In `RABBITMQ_URL`; restrict access; never log plaintext      |
| Queue event payloads | Internal Operational  | Deserialize via `MessagePayloadSerializer`; sanitize in logs |
| Application logs     | Internal Operational  | Rotated locally (`max_files: 10`); JSON on stderr in `prod`  |

## Container security and runtime hardening

- **Dedicated Container Execution**: All runtime and verification workflows run inside Docker containers; host/WSL tool
  installations are prohibited.
- **RabbitMQ TLS Support**: Configured with `roslov_queue.rabbitmq.simple_ssl_context_provider` and
  `RABBITMQ_SSL_ENABLED` so production environments can enforce encrypted AMQP connections without code changes.
- **Memory & Log Bounds**: Static analysis tools and runtime workers operate with explicit memory bounds (`512M`) and
  log rotation (`max_files: 10`) in local and test environments.
