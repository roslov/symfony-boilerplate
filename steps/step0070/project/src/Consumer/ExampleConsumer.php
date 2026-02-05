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
 * Consumer: Marks a user as unsubscribed from a mailing list.
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
        // assert($dto instanceof SomeDto);
        $this->logger->info('Example consumer started.');
        // Some code...
        $this->logger->info('Example consumer completed.');
        return ConsumerInterface::MSG_ACK;
    }
}
