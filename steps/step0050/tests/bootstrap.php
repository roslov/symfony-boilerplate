<?php

declare(strict_types=1);

use Symfony\Component\Dotenv\Dotenv;

require_once dirname(__DIR__) . '/vendor/autoload.php';
// phpcs:disable SlevomatCodingStandard.Variables.DisallowSuperGlobalVariable.DisallowedSuperGlobalVariable
$_SERVER['APP_ENV'] = 'test';
$_ENV['APP_ENV'] = $_SERVER['APP_ENV'];
(new Dotenv())->bootEnv(dirname(__DIR__) . '/.env');
