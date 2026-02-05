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
        // Your code that will run before a test
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
