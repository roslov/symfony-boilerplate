#!/bin/bash
set -e

### Bootstraps a new microservice

# Color and logging constants
COLOR_RESET='\033[0m'
COLOR_GREEN='\033[0;32m'
COLOR_BOLD_GREEN='\033[1;32m'
COLOR_GRAY='\033[0;90m'
COLOR_CYAN='\033[0;36m'
LOG_START="\n${COLOR_CYAN}===> ${COLOR_GREEN}"
LOG_END="${COLOR_RESET}"

# ======================================================================================================================
# === Helper Functions =================================================================================================
# ======================================================================================================================

# Logs a primary pipeline step header
logStep()
{
    local message="$1"
    echo -e "${LOG_START}${message}${LOG_END}"
}

# Logs a secondary sub-step message
logSubStep()
{
    local message="$1"
    echo -e "${COLOR_GRAY}${message}${LOG_END}"
}

# Executes a command inside the boilerplate Docker container
runInContainer()
{
    docker compose run --rm boilerplate "$@"
}

# Installs Composer packages that require Symfony Flex contrib recipes
requireWithContrib()
{
    runInContainer composer config extra.symfony.allow-contrib true --json
    runInContainer composer require "$@"
    runInContainer composer config extra.symfony.allow-contrib false --json
    runInContainer composer update --lock
}

# Updates composer.json in place using a jq filter
updateComposerJsonWithJq()
{
    local filter="$1"

    runInContainer jq --indent 4 "${filter}" composer.json > composer.tmp.json
    mv composer.tmp.json composer.json
}

# Updates composer.json using a PHP snippet from stdin that modifies $composer
updateComposerJsonWithPhp()
{
    local phpCode
    phpCode="$(cat)"

    runInContainer php -r '
        $file = "composer.json";
        $composer = json_decode(file_get_contents($file), true, flags: JSON_THROW_ON_ERROR);
    '"${phpCode}"'
        file_put_contents($file, json_encode($composer, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . PHP_EOL);
    '
}

# Prepends the contents of a source file to the beginning of a target file
prependToFile()
{
    local sourceFile="$1"
    local targetFile="$2"
    local newContent
    local oldContent

    newContent="$(cat "${sourceFile}")"
    oldContent="$(cat "${targetFile}")"
    printf "%s\n%s\n" "${newContent}" "${oldContent}" > "${targetFile}"
}

# Renders a template file to a target path using envsubst with an explicit variable whitelist
renderTemplate()
{
    local sourceFile="$1"
    local targetFile="$2"
    local variables="$3"
    local tmpFile="${targetFile}.tmp"

    envsubst "${variables}" < "${sourceFile}" > "${tmpFile}"
    mv "${tmpFile}" "${targetFile}"
}

# Replaces the ${REPLACE} placeholder in a target file with the contents of a snippet file
replacePlaceholder()
{
    local targetFile="$1"
    local snippetFile="$2"
    local tmpFile="${targetFile}.tmp"

    REPLACE="$(cat "${snippetFile}")" \
        envsubst '${REPLACE}' \
        < "${targetFile}" \
        > "${tmpFile}"
    mv "${tmpFile}" "${targetFile}"
}

# Fixes and validates files
#
# `rector` should be run twice to guarantee all changes are made.
fixAndValidateFiles()
{
    if [[ -f vendor/bin/rector ]]; then
        logSubStep 'Fixing files with Rector....'
        runInContainer rector
        runInContainer rector
    fi

    logSubStep 'Fixing files with PHP CBF....'
    runInContainer composer phpcbf . || true

    logSubStep 'Validating files....'
    runInContainer composer test:static

    logSubStep 'Running unit tests....'
    runInContainer composer test:unit
}

# Normalizes composer.json
normalizeComposer()
{
    logSubStep 'Normalizing composer.json....'
    runInContainer composer bump
    runInContainer composer normalize
}

# Commits all files with the [init] prefix
commit()
{
    local message="$1"
    git add .
    git commit -m "[init] ${message}"
}

# ======================================================================================================================
# === Main Pipeline ====================================================================================================
# ======================================================================================================================

echo -e "${COLOR_CYAN}××××× ${COLOR_BOLD_GREEN}Bootstrapping a new microservice ${COLOR_CYAN}×××××${LOG_END}"

########################################################################################################################
# Environment & Workspace Initialization
########################################################################################################################

logStep 'Loading environment variables...'
set -a
source .env.dist
source .env
set +a

logStep 'Preparing the `app` folder...'
rm -rf app
mkdir app

logStep 'Building images...'
export HOST_USER="$(id -un)"
export HOST_GROUP="$(id -gn)"
export HOST_UID="$(id -u)"
export HOST_GID="$(id -g)"
docker compose build

logStep 'Switching to the `app` folder...'
cd app

########################################################################################################################
# Step 0000: Symfony Skeleton & Git Initialization
########################################################################################################################

logStep "Initializing git and installing Symfony skeleton v${SYMFONY_VERSION}..."
runInContainer composer create-project symfony/skeleton:"${SYMFONY_VERSION}.x" .
git init
git branch -m main
commit "Installed Symfony skeleton v${SYMFONY_VERSION}"

########################################################################################################################
# Step 0010: Git Ignore Configuration
########################################################################################################################

logStep 'Updating .gitignore...'
prependToFile ../steps/step0010/.gitignore .gitignore
commit 'Updated .gitignore'

########################################################################################################################
# Step 0020: EditorConfig & Git Attributes
########################################################################################################################

logStep 'Adding .editorconfig and .gitattributes...'
cp ../steps/step0020/.[!.]* ./
commit 'Added .editorconfig and .gitattributes'

########################################################################################################################
# Step 0030: Initial README.md
########################################################################################################################

logStep 'Adding .README.md...'
HEADER_LINE="$(echo "${PROJECT_FULL_NAME}" | tr '[:print:]' '=')" \
    renderTemplate \
        ../steps/step0030/README.md \
        README.md \
        '${PROJECT_FULL_NAME} ${PROJECT_DESCRIPTION} ${HEADER_LINE} ${REPO_SITE} ${VENDOR} ${PARENT_PROJECT_FULL_NAME}'
commit 'Added README.md'

########################################################################################################################
# Step 0035: Composer Metadata, PHP 8.5 Requirement & Normalization Plugin
########################################################################################################################

logStep 'Updating composer.json...'
runInContainer composer config name "${VENDOR}/${PROJECT_NAME}"
runInContainer composer config description "${PROJECT_FULL_NAME}"
updateComposerJsonWithJq '{name, description} + del(.name, .description)'
runInContainer composer require -W 'php:>=8.5'
updateComposerJsonWithJq \
    '.replace += {"symfony/polyfill-php83":"*","symfony/polyfill-php84":"*","symfony/polyfill-php85":"*"}'
runInContainer composer update
runInContainer composer config allow-plugins.ergebnis/composer-normalize true
runInContainer composer require --dev -W ergebnis/composer-normalize
normalizeComposer
commit 'Updated composer.json'

########################################################################################################################
# Step 0038: Host Development Makefile
########################################################################################################################

logStep 'Adding Makefile...'
renderTemplate ../steps/step0038/Makefile Makefile '${PROJECT_NAME}'
commit 'Added Makefile'

########################################################################################################################
# Step 0040: PHP_CodeSniffer (PSR-12 Ext) & Parallel Syntax Linting
########################################################################################################################

logStep 'Adding CodeSniffer with PSR-12 Ext rules and syntax validation...'
runInContainer composer config --no-plugins \
    allow-plugins.dealerdirect/phpcodesniffer-composer-installer true
requireWithContrib --dev -W \
    php-parallel-lint/php-console-highlighter \
    php-parallel-lint/php-parallel-lint \
    roslov/psr12ext

updateComposerJsonWithPhp <<'PHP'
$composer['scripts'] ??= [];
$composer['scripts']['phpcs'] = 'phpcs -d memory_limit=512M --extensions=php --colors --standard=ruleset.xml'
    . ' --runtime-set php_version "$(php -r \'echo PHP_VERSION_ID;\')" -p -s';
$composer['scripts']['phpcbf'] = 'phpcbf -d memory_limit=512M --extensions=php --colors --standard=ruleset.xml'
    . ' --runtime-set php_version "$(php -r \'echo PHP_VERSION_ID;\')" -p';
$composer['scripts']['syntax'] = 'parallel-lint --colors --exclude bin --exclude vendor --exclude var';
$composer['scripts']['test'] = ['@test:static', '@test:unit', '@test:integration'];
$composer['scripts']['test:static'] = [
    '@composer validate',
    '@composer normalize --dry-run',
    '@syntax .',
    'bin/console lint:container',
    'bin/console lint:yaml config src',
    '@phpcs .',
];
$composer['scripts']['test:unit'] = "echo 'Notice: Unit tests are not implemented.'";
$composer['scripts']['test:integration'] = "echo 'Notice: Integration tests are not implemented.'";

$composer['scripts-descriptions'] ??= [];
$composer['scripts-descriptions']['phpcs'] = 'Runs PHP CodeSniffer';
$composer['scripts-descriptions']['phpcbf'] = 'Fixes PHP CodeSniffer issues';
$composer['scripts-descriptions']['syntax'] = 'Checks PHP syntax';
$composer['scripts-descriptions']['test'] = 'Runs static analysis and all tests';
$composer['scripts-descriptions']['test:static'] = 'Runs static analysis';
$composer['scripts-descriptions']['test:unit'] = 'Runs unit tests';
$composer['scripts-descriptions']['test:integration'] = 'Runs integration tests';
PHP

cp ../steps/step0040/ruleset.xml ./
sed -i \
    '/^namespace App;/c\// phpcs:disable SlevomatCodingStandard.Classes.TraitUseSpacing.IncorrectLinesCountAfterLastUse\n\nnamespace App;' \
    src/Kernel.php

sed -i '/^Code quality check$/,/^\*\*TBD\*\*$/c\${REPLACE}' README.md
replacePlaceholder README.md ../steps/step0040/coding-style.md
echo >> README.md
cat ../steps/step0040/faq.md >> README.md

normalizeComposer
fixAndValidateFiles
commit 'Added CodeSniffer with PSR-12 Ext rules. Added syntax validation'

########################################################################################################################
# Step 0042: Base Packages (Monolog, Serializer, Debug Bundle)
########################################################################################################################

logStep 'Installing base packages...'
runInContainer composer require -W \
    symfony/monolog-bundle \
    symfony/serializer
runInContainer composer require --dev -W symfony/debug-bundle
normalizeComposer
fixAndValidateFiles
commit 'Installed base packages'

########################################################################################################################
# Step 0045: Monolog Configuration (Rotation, Level, and Stack Traces)
########################################################################################################################

logStep 'Adding log file rotation for local environment...'
cp ../steps/step0045/monolog.yaml config/packages/monolog.yaml
commit 'Added log file rotation for local environment'

logStep 'Decreasing log level for production...'
sed -i \
    '/when@prod:/,/^[^[:space:]]/ s/\(action_level:\s*\)error/\1info/' \
    config/packages/monolog.yaml
commit 'Decreased log level from `error` to `info` for production'

logStep 'Adding exception stack trace for production logs...'
sed -i \
    's/formatter: monolog\.formatter\.json/formatter: app.monolog.json_formatter_with_trace/g' \
    config/packages/monolog.yaml
sed -i '/# add more service definitions when explicit configuration is needed/{
N
c\
    # Services\
    app.monolog.json_formatter_with_trace:\
        class: Monolog\\Formatter\\JsonFormatter\
        arguments:\
            $includeStacktraces: true
}' config/services.yaml
commit 'Added exception stack trace for production logs'

########################################################################################################################
# Step 0050: Codeception Installation & Suite Configuration
########################################################################################################################

logStep 'Installing and bootstrapping Codeception with modules...'
CODECEPTION_VERSION=5.3
runInContainer composer require --dev -W -n \
    "codeception/codeception:^${CODECEPTION_VERSION}" \
    codeception/module-asserts \
    codeception/module-symfony \
    codeception/module-phpbrowser
normalizeComposer
runInContainer codecept bootstrap
commit "Tests: Installed and bootstrapped Codeception v${CODECEPTION_VERSION} with modules Asserts, PhpBrowser and Symfony"

logStep 'Configuring Codeception...'
sed -i '/^Testing$/,/^\*\*TBD\*\*$/c\${REPLACE}' README.md
replacePlaceholder README.md ../steps/step0050/tests.md
cat ../steps/step0050/codeception.yml >> codeception.yml

sed -i 's/"App\\\\Tests\\\\": "tests\/"/"Tests\\\\": "tests\/"/' composer.json
runInContainer composer dump-autoload
runInContainer composer remove --dev -W codeception/module-phpbrowser

sed -i \
    '/^    <exclude-pattern>var\/\*<\/exclude-pattern>$/c\    <exclude-pattern>var/*</exclude-pattern>\n    <exclude-pattern>tests/Support/_generated/*</exclude-pattern>' \
    ruleset.xml
sed -i \
    '/^<\/ruleset>$/c\    <!-- Rules for tests -->\n    <rule ref="PSR2.Methods.MethodDeclaration.Underscore">\n        <exclude-pattern>tests/*</exclude-pattern>\n    </rule>\n</ruleset>' \
    ruleset.xml
sed -i \
    '/^        # add a framework module here$/c\        - Symfony:\n              app_path: src\n              environment: test\n        - Asserts' \
    tests/Functional.suite.yml

rm tests/Acceptance.suite.yml
rm tests/Support/AcceptanceTester.php
cp -rf ../steps/step0050/tests/* tests/

updateComposerJsonWithPhp <<'PHP'
$composer['scripts']['test:static'] = [
    '@composer validate',
    '@composer normalize --dry-run',
    '@syntax .',
    'bin/console lint:container',
    'bin/console lint:yaml config src tests',
    '@phpcs .',
];
$composer['scripts']['test:unit'] = 'codecept run';
PHP

normalizeComposer
fixAndValidateFiles
commit 'Tests: Configured Codeception'

########################################################################################################################
# Step 0060: PHPStan Static Analysis
########################################################################################################################

logStep 'Adding PHPStan...'
sed -i \
    '/^# Checks Composer dependencies, coding style and PHP syntax as a single command\.$/c\# Checks Composer dependencies, coding style, PHPStan rules and PHP syntax as a single command.' \
    README.md
sed -i \
    '/^composer syntax \.$/c\composer syntax .\n# Runs PHPStan analysis\ncomposer phpstan' \
    README.md

updateComposerJsonWithPhp <<'PHP'
$composer['scripts']['phpstan'] = 'phpstan analyse --memory-limit=512M';
$composer['scripts']['test:static'] = array_merge(
    $composer['scripts']['test:static'],
    ['codecept build', '@phpstan']
);
$composer['scripts-descriptions']['phpstan'] = 'Runs PHPStan static analysis';
PHP

requireWithContrib --dev -W phpstan/phpstan-symfony
# TODO: Uncomment for Doctrine support
#runInContainer composer require --dev -W phpstan/phpstan-doctrine

cp -rf ../steps/step0060/stubs stubs
normalizeComposer

sed -i 's/level: 6/level: max/' phpstan.dist.neon
cat <<'EOF' >> phpstan.dist.neon
    excludePaths:
        - tests/Support/_generated/
    stubFiles:
        - stubs/CodeceptionExample.stub
EOF
# TODO: Uncomment for Doctrine support
#echo 'includes:' >> phpstan.dist.neon
#echo '    - vendor/phpstan/phpstan-doctrine/extension.neon' >> phpstan.dist.neon

sed -i '/return static function (array \$context) {/,/};/c\
/** @phpstan-ignore argument.type */\
return static fn (array $context): Kernel => new Kernel($context['\''APP_ENV'\''], (bool) $context['\''APP_DEBUG'\'']);' \
    public/index.php

fixAndValidateFiles
commit 'Added PHPStan'

########################################################################################################################
# Step 0070: Roslov Queue Bundle & RabbitMQ Consumer Setup
########################################################################################################################

logStep 'Setting up Queue bundle...'
requireWithContrib -W roslov/queue-bundle
normalizeComposer

sed -i \
    '/^RABBITMQ_URL=amqp:\/\/guest:guest@localhost:5672$/cRABBITMQ_URL=amqp://guest:guest@rabbitmq:5672' \
    .env
cat <<EOF >> .env

# Microservice name
SERVICE_NAME=${PROJECT_NAME}

# Disables SSL for RabbitMQ
RABBITMQ_SSL_ENABLED=false
EOF

cat <<'EOF' >> .env.test

###> php-amqplib/rabbitmq-bundle ###
RABBITMQ_URL=amqp://guest:guest@test-rabbitmq:5672
###< php-amqplib/rabbitmq-bundle ###
EOF

sed -i '/^Testing$/,/^-------$/c\${REPLACE}\n\n\nTesting\n-------' README.md
replacePlaceholder README.md ../steps/step0070/consumers.md

sed -i '/^parameters:/a\${REPLACE}' config/services.yaml
replacePlaceholder config/services.yaml ../steps/step0070/parameters.yaml

cp -r ../steps/step0070/project/* ./
renderTemplate \
    config/packages/old_sound_rabbit_mq.yaml \
    config/packages/old_sound_rabbit_mq.yaml \
    '${PROJECT_NAME}'
rm src/Consumer/.gitignore

fixAndValidateFiles
commit 'Set up Queue bundle and added consumer stub'

########################################################################################################################
# Step 0080: Rector Automated Refactoring
########################################################################################################################

logStep 'Adding Rector...'
sed -i \
    '/^# Checks Composer dependencies, coding style, PHPStan rules and PHP syntax as a single command.$/c\# Checks Composer dependencies, coding style, PHPStan rules, PHP syntax and others as a single command.' \
    README.md

updateComposerJsonWithPhp <<'PHP'
$composer['scripts']['test:static'] = array_merge(
    $composer['scripts']['test:static'],
    ['rector --dry-run']
);
PHP

runInContainer composer require --dev -W rector/rector
normalizeComposer
# Creates the default Rector config
runInContainer rector -n
fixAndValidateFiles
commit 'Added Rector'

logStep 'Configuring Rector...'
cp ../steps/step0080/rector.php rector.php
fixAndValidateFiles
commit 'Configured Rector'

########################################################################################################################
# Step 0090: AI Agent Support (AGENTS.md, Documentation, and Skills)
########################################################################################################################

logStep 'Adding AI agent support...'
sed -i '/^Consumers$/,/^---------$/c\${REPLACE}\n\n\nConsumers\n---------' README.md
replacePlaceholder README.md ../steps/step0090/documentation.md

cp -rf ../steps/step0090/project/. ./
AGENT_TEMPLATE_VARS='${PROJECT_NAME} ${PROJECT_FULL_NAME} ${PROJECT_DESCRIPTION} ${PARENT_PROJECT_FULL_NAME} ${SYMFONY_VERSION}'
for templateFile in \
    AGENTS.md \
    docs/requirements.md \
    docs/architecture.md \
    docs/security.md \
    docs/testing.md \
    docs/acceptance-criteria.md \
    .agents/skills/docker-verification/SKILL.md \
    .agents/skills/testing/SKILL.md \
    .agents/skills/queue-and-messaging/SKILL.md; do
    renderTemplate "${templateFile}" "${templateFile}" "${AGENT_TEMPLATE_VARS}"
done

fixAndValidateFiles
commit 'Added AI agent support'

########################################################################################################################
# Step 1010: CI Pipeline (Jenkinsfile)
########################################################################################################################

logStep 'Configuring CI...'
renderTemplate ../steps/step1010/Jenkinsfile Jenkinsfile '${PROJECT_NAME}'
commit 'CI: Added Jenkinsfile'

########################################################################################################################
# Summary
########################################################################################################################

logStep 'Displaying the current git log...'
git --no-pager log

logStep 'Done!'
