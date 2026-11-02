---
name: code-quality-and-testing-templates
description: >-
  Maintain and update the static analysis, coding standard, refactoring, and testing templates
  (`ruleset.xml`, `phpstan.dist.neon`, `CodeceptionExample.stub`, `rector.php`, and Codeception
  suites in `steps/step0040`, `step0050`, `step0060`, and `step0080`). Use when modifying quality
  rules, Composer scripts, PHPStan settings, Rector rules, or Codeception test templates.
---

# Code Quality and Testing Templates Workflow

This skill covers the configuration and maintenance of the static analysis, code formatting, automated refactoring, and
testing templates installed into every generated microservice.

## Tooling Overview Across Steps

1. **PHP_CodeSniffer & Parallel Lint (`steps/step0040` + `create-microservice.sh`)**:
   - Packages: `roslov/psr12ext`, `php-parallel-lint/php-parallel-lint`, `php-parallel-lint/php-console-highlighter`.
   - Standard: `steps/step0040/ruleset.xml` referencing `vendor/roslov/psr12ext/PSR12Ext`.
   - Exclusions in `ruleset.xml`:
     - `config/reference.php`
     - `var/*`
     - `vendor/*`
     - `tests/Support/_generated/*` (added in `step0050`)
     - `PSR2.Methods.MethodDeclaration.Underscore` excluded for `tests/*` (allowing Codeception `_before()` methods).
   - Note on `src/Kernel.php`: `create-microservice.sh` prepends
     `// phpcs:disable SlevomatCodingStandard.Classes.TraitUseSpacing.IncorrectLinesCountAfterLastUse` above
     `namespace App;` in `src/Kernel.php`.

2. **Codeception Testing Framework (`steps/step0050` + `create-microservice.sh`)**:
   - Packages: `codeception/codeception:^5.3`, `codeception/module-asserts`, `codeception/module-symfony`.
   - `codeception/module-phpbrowser` is installed during `codecept bootstrap` so standard suites generate cleanly, and
     then removed along with `tests/Acceptance.suite.yml` and `tests/Support/AcceptanceTester.php`.
   - `autoload-dev` namespace in `composer.json` is rewritten from `App\Tests\` to `Tests\`.
   - `tests/Functional.suite.yml` enables the `Symfony` (`app_path: 'src'`, `environment: 'test'`) and `Asserts`
     modules.
   - Template tests:
     - `steps/step0050/tests/Unit/ExampleTest.php` (`Tests\Unit\ExampleTest extends Codeception\Test\Unit`)
     - `steps/step0050/tests/Functional/ExampleCest.php` (`Tests\Functional\ExampleCest`)

3. **PHPStan (`steps/step0060` + `create-microservice.sh`)**:
   - Package: `phpstan/phpstan-symfony`.
   - Configuration (`phpstan.dist.neon`):
     - Upgraded from `level: 6` to `level: max`.
     - `excludePaths`: `tests/Support/_generated/`.
     - `stubFiles`: `stubs/CodeceptionExample.stub` (provides generic `@template T of array` annotations for
       `Codeception\Example`).
   - Doctrine Support Note: `create-microservice.sh` contains commented `# TODO: Uncomment for Doctrine support` lines
     for `phpstan/phpstan-doctrine`.
   - `public/index.php` is rewritten to use an arrow function with `/** @phpstan-ignore argument.type */` to satisfy
     `level: max`.

4. **Rector (`steps/step0080/rector.php` + `create-microservice.sh`)**:
   - Package: `rector/rector`.
   - Configured in `steps/step0080/rector.php` with:
     - Paths: `config`, `public`, `src`, `tests`.
     - Skip rules: `tests/Support/_generated`, `config/reference.php`, `RemoveAlwaysTrueIfConditionRector`,
       `CatchExceptionNameMatchingTypeRector`, `AddReturnDocblockForArrayDimAssignedObjectRector`,
       `PrivatizeLocalGetterToPropertyRector`, and `PrivatizeFinalClassMethodRector` on `tests/`.
     - Attributes sets: `symfony: true, doctrine: true, phpunit: true`.
     - Composer-based sets: `twig: true, doctrine: true, symfony: true`.
     - Prepared sets: `deadCode`, `codeQuality`, `codingStyle`, `typeDeclarations`, `typeDeclarationDocblocks`,
       `privatization`, `instanceOf`, `if`, `earlyReturn`, `rectorPreset`, `phpunitCodeQuality`, `phpunitNarrowAsserts`,
       `phpunitMockToStub`, `doctrineCodeQuality`, `symfonyCodeQuality`, `symfonyConfigs`.

---

## Composer Scripts Pipeline in Generated `composer.json`

By the end of `create-microservice.sh`, the generated `composer.json` defines:

- **`phpcs`**: Runs `phpcs -d memory_limit=512M --extensions=php --colors --standard=ruleset.xml` with `--runtime-set`
  `php_version "$(php -r 'echo PHP_VERSION_ID;')" -p -s`.
- **`phpcbf`**: Runs `phpcbf -d memory_limit=512M --extensions=php --colors --standard=ruleset.xml` with `--runtime-set`
  `php_version "$(php -r 'echo PHP_VERSION_ID;')" -p`.
- **`phpstan`**: Runs `phpstan analyse --memory-limit=512M`.
- **`syntax`**: Runs `parallel-lint --colors --exclude bin --exclude vendor --exclude var`.
- **`test`**: Runs `["@test:static", "@test:unit", "@test:integration"]`.
- **`test:static`**: Runs `["@composer validate", "@composer normalize --dry-run", "@syntax .",`
  `"bin/console lint:container", "bin/console lint:yaml config src tests", "@phpcs .", "codecept build",`
  `"@phpstan", "rector --dry-run"]`.
- **`test:unit`**: Runs `codecept run`.
- **`test:integration`**: Runs `echo 'Notice: Integration tests are not implemented.'`.

---

## Modifying Quality or Testing Templates

When updating any rule in `steps/step0040/ruleset.xml`, `steps/step0050/tests/`, `steps/step0060/stubs/`, or
`steps/step0080/rector.php`:

1. Ensure the template files in `steps/` remain compatible with each other (for example, Rector transformations must not
   violate `PSR12Ext` in `ruleset.xml`, and `ExampleTest.php` / `ExampleCest.php` must pass PHPStan `level: max`).
2. Copy the updated template into `./app` (if present) and run `fixAndValidateFiles` commands inside the `boilerplate`
   container to confirm zero conflicts between Rector, PHPCS, and PHPStan.

---

## Skill Maintenance & Self-Enforcement

Whenever updating PHPCS rules, PHPStan configuration, Codeception suites, or Rector prepared sets/skips, update this
skill file (`.agents/skills/code-quality-and-testing-templates/SKILL.md`).
