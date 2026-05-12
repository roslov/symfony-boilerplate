#!/bin/bash
set -e

### Bootstraps a new microservice

# Fixes file permissions
fixPermissions()
{
    echo -e "${COLOR_GRAY}Fixing permissions...${LOG_END}"
    chown "$(id -un $SUDO_USER):$(id -gn $SUDO_USER)" -R .
}

# Fixes and validates files
#
# `rector` should be run twice to guarantee all changes are made.
fixAndValidateFiles()
{
    [[ -f vendor/bin/rector ]] \
        && echo -e "${COLOR_GRAY}Fixing files with Rector....${LOG_END}" \
        && docker compose run --rm boilerplate rector \
        && docker compose run --rm boilerplate rector

    echo -e "${COLOR_GRAY}Fixing files with PHP CBF....${LOG_END}"
    docker compose run --rm boilerplate composer phpcbf . || true

    echo -e "${COLOR_GRAY}Validating files....${LOG_END}"
    docker compose run --rm boilerplate composer test:static

    echo -e "${COLOR_GRAY}Running unit tests....${LOG_END}"
    docker compose run --rm boilerplate composer test:unit
}

# Normalizes composer.json
normalizeComposer()
{
    echo -e "${COLOR_GRAY}Normalizing composer.json....${LOG_END}"
    docker compose run --rm boilerplate composer normalize
}

# Commits all files
commit()
{
    local message="$1"
    git add .
    git commit -m "[init] ${message}"
}

# Main entrypoint

COLOR_RESET='\033[0m'
COLOR_GREEN='\033[0;32m'
COLOR_BOLD_GREEN='\033[1;32m'
COLOR_GRAY='\033[0;90m'
COLOR_CYAN='\033[0;36m'
LOG_START="\n${COLOR_CYAN}===> ${COLOR_GREEN}"
LOG_END="${COLOR_RESET}"

########################################################################################################################
echo -e "${COLOR_CYAN}××××× ${COLOR_BOLD_GREEN}Bootstrapping a new microservice ${COLOR_CYAN}×××××${LOG_END}"

########################################################################################################################
echo -e "${LOG_START}Loading environment variables...${LOG_END}"
source .env.dist
source .env

########################################################################################################################
echo -e "${LOG_START}Preparing the \`app\` folder...${LOG_END}"
rm -rf app
mkdir app

########################################################################################################################
echo -e "${LOG_START}Building images...${LOG_END}"
docker compose build

########################################################################################################################
echo -e "${LOG_START}Switching to the \`app\` folder...${LOG_END}"
cd app

########################################################################################################################
echo -e "${LOG_START}Initializing git and installing Symfony skeleton v${SYMFONY_VERSION}...${LOG_END}"
docker compose run --rm boilerplate composer create-project symfony/skeleton:"${SYMFONY_VERSION}.x" .
git init
git branch -m main
commit "Installed Symfony skeleton v${SYMFONY_VERSION}"

########################################################################################################################
echo -e "${LOG_START}Updating .gitignore...${LOG_END}"
newContent=$(cat ../steps/step0010/.gitignore)
oldContent=$(cat .gitignore)
fixPermissions
printf "%s\n%s\n" "$newContent" "$oldContent" > .gitignore
commit 'Updated .gitignore'

########################################################################################################################
echo -e "${LOG_START}Adding .editorconfig and .gitattributes...${LOG_END}"
cp ../steps/step0020/.[!.]* ./
commit 'Added .editorconfig and .gitattributes'

########################################################################################################################
echo -e "${LOG_START}Adding .README.md...${LOG_END}"
PARENT_PROJECT_FULL_NAME="${PARENT_PROJECT_FULL_NAME}" \
VENDOR="${VENDOR}" \
REPO_SITE="${REPO_SITE}" \
PROJECT_FULL_NAME="${PROJECT_FULL_NAME}" \
PROJECT_DESCRIPTION="${PROJECT_DESCRIPTION}" \
HEADER_LINE="$(echo "${PROJECT_FULL_NAME}" | tr '[:print:]' '=')" \
    envsubst '${PROJECT_FULL_NAME} ${PROJECT_DESCRIPTION} ${HEADER_LINE} ${REPO_SITE} ${VENDOR} ${PARENT_PROJECT_FULL_NAME}' \
    < ../steps/step0030/README.md \
    > README.md
commit 'Added README.md'

########################################################################################################################
echo -e "${LOG_START}Updating composer.json...${LOG_END}"
docker compose run --rm boilerplate composer config name "${VENDOR}/${PROJECT_NAME}"
docker compose run --rm boilerplate composer config description "${PROJECT_FULL_NAME}"
docker compose run --rm boilerplate \
    jq --indent 4 '{name, description} + del(.name, .description)' composer.json > composer.tmp.json \
    && mv composer.tmp.json composer.json
docker compose run --rm boilerplate composer require -W 'php:>=8.5'
docker compose run --rm boilerplate \
    jq --indent 4 '.replace += {"symfony/polyfill-php83":"*","symfony/polyfill-php84":"*","symfony/polyfill-php85":"*"}' \
        composer.json > composer.tmp.json \
    && mv composer.tmp.json composer.json
docker compose run --rm boilerplate composer update
docker compose run --rm boilerplate composer config allow-plugins.ergebnis/composer-normalize true
docker compose run --rm boilerplate composer require --dev -W ergebnis/composer-normalize
normalizeComposer
commit 'Updated composer.json'

########################################################################################################################
echo -e "${LOG_START}Adding Makefile...${LOG_END}"
PROJECT_NAME="${PROJECT_NAME}" \
    envsubst '${PROJECT_NAME}' \
    < ../steps/step0038/Makefile \
    > Makefile
commit 'Added Makefile'

########################################################################################################################
echo -e "${LOG_START}Adding CodeSniffer with PSR-12 Ext rules and syntax validation...${LOG_END}"
docker compose run --rm boilerplate composer config extra.symfony.allow-contrib true --json
docker compose run --rm boilerplate composer config --no-plugins \
    allow-plugins.dealerdirect/phpcodesniffer-composer-installer true
docker compose run --rm boilerplate composer require --dev -W \
    php-parallel-lint/php-console-highlighter \
    php-parallel-lint/php-parallel-lint \
    roslov/psr12ext
docker compose run --rm boilerplate composer config extra.symfony.allow-contrib false --json
docker compose run --rm boilerplate composer update --lock
docker compose run --rm boilerplate php -r '
$f="composer.json";
$j=json_decode(file_get_contents($f), true, flags: JSON_THROW_ON_ERROR);
$j["scripts"] ??= [];
$j["scripts"]["phpcs"]="phpcs -d memory_limit=512M --extensions=php --colors --standard=ruleset.xml --runtime-set php_version \"$(php -r '\''echo PHP_VERSION_ID;'\'')\" -p -s";
$j["scripts"]["phpcbf"]="phpcbf -d memory_limit=512M --extensions=php --colors --standard=ruleset.xml --runtime-set php_version \"$(php -r '\''echo PHP_VERSION_ID;'\'')\" -p";
$j["scripts"]["syntax"]="parallel-lint --colors --exclude bin --exclude vendor --exclude var";
$j["scripts"]["test"]=["@test:static","@test:unit","@test:integration"];
$j["scripts"]["test:static"]=["@composer validate","@composer normalize --dry-run","@syntax .","bin/console lint:container","bin/console lint:yaml config src","@phpcs ."];
$j["scripts"]["test:unit"]="echo '\''Notice: Unit tests are not implemented.'\''";
$j["scripts"]["test:integration"]="echo '\''Notice: Integration tests are not implemented.'\''";
$j["scripts-descriptions"] ??= [];
$j["scripts-descriptions"]["phpcs"]="Runs PHP CodeSniffer";
$j["scripts-descriptions"]["phpcbf"]="Fixes PHP CodeSniffer issues";
$j["scripts-descriptions"]["syntax"]="Checks PHP syntax";
$j["scripts-descriptions"]["test"]="Runs static analysis and all tests";
$j["scripts-descriptions"]["test:static"]="Runs static analysis";
$j["scripts-descriptions"]["test:unit"]="Runs unit tests";
$j["scripts-descriptions"]["test:integration"]="Runs integration tests";
file_put_contents($f, json_encode($j, JSON_PRETTY_PRINT|JSON_UNESCAPED_SLASHES).PHP_EOL);
'
cp ../steps/step0040/ruleset.xml ./
sed -i \
    '/^namespace App;/c\// phpcs:disable SlevomatCodingStandard.Classes.TraitUseSpacing.IncorrectLinesCountAfterLastUse\n\nnamespace App;' \
    src/Kernel.php
sed -i \
    '/^Code quality check$/,/^\*\*TBD\*\*$/c\${REPLACE}' \
    README.md
REPLACE="$(cat ../steps/step0040/coding-style.md)" \
    envsubst '${REPLACE}' \
    < README.md \
    > README2.md
rm README.md && mv README2.md README.md
echo >> README.md
cat ../steps/step0040/faq.md >> README.md
normalizeComposer
fixAndValidateFiles
commit 'Added CodeSniffer with PSR-12 Ext rules. Added syntax validation'

########################################################################################################################
echo -e "${LOG_START}Installing base packages...${LOG_END}"
docker compose run --rm boilerplate composer require -W \
    symfony/monolog-bundle \
    symfony/serializer
docker compose run --rm boilerplate composer require --dev -W symfony/debug-bundle
normalizeComposer
fixAndValidateFiles
commit 'Installed base packages'

########################################################################################################################
echo -e "${LOG_START}Adding log file rotation for local environment...${LOG_END}"
cp ../steps/step0045/monolog.yaml config/packages/monolog.yaml
commit 'Added log file rotation for local environment'

########################################################################################################################
echo -e "${LOG_START}Decreasing log level for production...${LOG_END}"
sed -i \
    '/when@prod:/,/^[^[:space:]]/ s/\(action_level:\s*\)error/\1info/' \
    config/packages/monolog.yaml
commit 'Decreased log level from `error` to `info` for production'

########################################################################################################################
echo -e "${LOG_START}Adding exception stack trace for production logs...${LOG_END}"
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
echo -e "${LOG_START}Installing and bootstrapping Codeception with modules...${LOG_END}"
CODECEPTION_VERSION=5.3
docker compose run --rm boilerplate composer require --dev -W -n \
    codeception/codeception:^${CODECEPTION_VERSION} \
    codeception/module-asserts \
    codeception/module-symfony \
    codeception/module-phpbrowser
normalizeComposer
docker compose run --rm boilerplate codecept bootstrap
commit "Tests: Installed and bootstrapped Codeception v${CODECEPTION_VERSION} with modules Asserts, PhpBrowser and Symfony"

########################################################################################################################
echo -e "${LOG_START}Configuring Codeception...${LOG_END}"
sed -i \
    '/^Testing$/,/^\*\*TBD\*\*$/c\${REPLACE}' \
    README.md
REPLACE="$(cat ../steps/step0050/tests.md)" \
    envsubst '${REPLACE}' \
    < README.md \
    > README2.md
rm README.md && mv README2.md README.md
fixPermissions
cat ../steps/step0050/codeception.yml >> codeception.yml
sed -i 's/"App\\\\Tests\\\\": "tests\/"/"Tests\\\\": "tests\/"/' composer.json
docker compose run --rm boilerplate composer dump-autoload
docker compose run --rm boilerplate composer remove --dev -W codeception/module-phpbrowser
sed -i \
    '/^    <exclude-pattern>var\/\*<\/exclude-pattern>$/c\    <exclude-pattern>var/*</exclude-pattern>\n    <exclude-pattern>tests/Support/_generated/*</exclude-pattern>' \
    ruleset.xml
sed -i \
    '/^<\/ruleset>$/c\    <!-- Rules for tests -->\n    <rule ref="PSR2.Methods.MethodDeclaration.Underscore">\n        <exclude-pattern>tests/*</exclude-pattern>\n    </rule>\n</ruleset>' \
    ruleset.xml
sed -i \
    '/^        # add a framework module here$/c\        - Symfony:\n              app_path: 'src'\n              environment: 'test'\n        - Asserts' \
    tests/Functional.suite.yml
rm tests/Acceptance.suite.yml
rm tests/Support/AcceptanceTester.php
cp -rf ../steps/step0050/tests/* tests/
docker compose run --rm boilerplate php -r '
$f="composer.json";
$j=json_decode(file_get_contents($f), true, flags: JSON_THROW_ON_ERROR);
$j["scripts"]["test:static"]=["@composer validate","@composer normalize --dry-run","@syntax .","bin/console lint:container","bin/console lint:yaml config src tests","@phpcs ."];
$j["scripts"]["test:unit"]="codecept run";
file_put_contents($f, json_encode($j, JSON_PRETTY_PRINT|JSON_UNESCAPED_SLASHES).PHP_EOL);
'
normalizeComposer
fixAndValidateFiles
commit 'Tests: Configured Codeception'

########################################################################################################################
echo -e "${LOG_START}Adding PHPStan...${LOG_END}"
sed -i \
    '/^# Checks Composer dependencies, coding style and PHP syntax as a single command\.$/c\# Checks Composer dependencies, coding style, PHPStan rules and PHP syntax as a single command.' \
    README.md
sed -i \
    '/^composer syntax \.$/c\composer syntax .\n# Runs PHPStan analysis\ncomposer phpstan' \
    README.md
docker compose run --rm boilerplate php -r '
$f="composer.json";
$j=json_decode(file_get_contents($f), true, flags: JSON_THROW_ON_ERROR);
$j["scripts"]["phpstan"]="phpstan analyse --memory-limit=512M";
$j["scripts"]["test:static"]=array_merge($j["scripts"]["test:static"], ["codecept build","@phpstan"]);
$j["scripts-descriptions"]["phpstan"]="Runs PHPStan static analysis";
file_put_contents($f, json_encode($j, JSON_PRETTY_PRINT|JSON_UNESCAPED_SLASHES).PHP_EOL);
'
docker compose run --rm boilerplate composer config extra.symfony.allow-contrib true --json
docker compose run --rm boilerplate composer require --dev -W phpstan/phpstan-symfony
docker compose run --rm boilerplate composer config extra.symfony.allow-contrib false --json
docker compose run --rm boilerplate composer update --lock
normalizeComposer
fixPermissions
echo '    excludePaths:' >> phpstan.dist.neon
echo '        - tests/Support/_generated/' >> phpstan.dist.neon
fixAndValidateFiles
commit 'Added PHPStan'

########################################################################################################################
echo -e "${LOG_START}Setting up Queue bundle...${LOG_END}"
docker compose run --rm boilerplate composer config extra.symfony.allow-contrib true --json
docker compose run --rm boilerplate composer require -W roslov/queue-bundle
docker compose run --rm boilerplate composer config extra.symfony.allow-contrib false --json
docker compose run --rm boilerplate composer update --lock
normalizeComposer
fixPermissions
sed -i \
    '/^RABBITMQ_URL=amqp:\/\/guest:guest@localhost:5672$/cRABBITMQ_URL=amqp://guest:guest@rabbitmq:5672' \
    .env
echo >> .env
echo '# Microservice name' >> .env
echo "SERVICE_NAME=${PROJECT_NAME}" >> .env
echo >> .env
echo '# Disables SSL for RabbitMQ' >> .env
echo 'RABBITMQ_SSL_ENABLED=false' >> .env
echo >> .env.test
echo '###> php-amqplib/rabbitmq-bundle ###' >> .env.test
echo 'RABBITMQ_URL=amqp://guest:guest@test-rabbitmq:5672' >> .env.test
echo '###< php-amqplib/rabbitmq-bundle ###' >> .env.test
sed -i \
    '/^Testing$/,/^-------$/c\${REPLACE}\n\n\nTesting\n-------' \
    README.md
REPLACE="$(cat ../steps/step0070/consumers.md)" \
    envsubst '${REPLACE}' \
    < README.md \
    > README2.md
rm README.md && mv README2.md README.md
sed -i '/^parameters:/a\${REPLACE}' config/services.yaml
REPLACE="$(cat ../steps/step0070/parameters.yaml)" \
    envsubst '${REPLACE}' \
    < config/services.yaml \
    > config/services2.yaml
rm config/services.yaml && mv config/services2.yaml config/services.yaml
cp -r ../steps/step0070/project/* ./
PROJECT_NAME="${PROJECT_NAME}" \
    envsubst '${PROJECT_NAME}' \
    < config/packages/old_sound_rabbit_mq.yaml \
    > config/packages/old_sound_rabbit_mq2.yaml
rm config/packages/old_sound_rabbit_mq.yaml
mv config/packages/old_sound_rabbit_mq2.yaml config/packages/old_sound_rabbit_mq.yaml
rm src/Consumer/.gitignore
fixAndValidateFiles
commit 'Set up Queue bundle and added consumer stub'

########################################################################################################################
echo -e "${LOG_START}Adding Rector...${LOG_END}"
sed -i \
    '/^# Checks Composer dependencies, coding style, PHPStan rules and PHP syntax as a single command.$/c\# Checks Composer dependencies, coding style, PHPStan rules, PHP syntax and others as a single command.' \
    README.md
docker compose run --rm boilerplate php -r '
$f="composer.json";
$j=json_decode(file_get_contents($f), true, flags: JSON_THROW_ON_ERROR);
$j["scripts"]["test:static"]=array_merge($j["scripts"]["test:static"], ["rector --dry-run"]);
file_put_contents($f, json_encode($j, JSON_PRETTY_PRINT|JSON_UNESCAPED_SLASHES).PHP_EOL);
'
docker compose run --rm boilerplate composer require --dev -W rector/rector
normalizeComposer
# Creates the default Rector config
yes | docker compose run --rm boilerplate rector
fixPermissions
fixAndValidateFiles
commit 'Added Rector'

########################################################################################################################
echo -e "${LOG_START}Configuring Rector...${LOG_END}"
cp ../steps/step0080/rector.php rector.php
fixPermissions
fixAndValidateFiles
commit 'Configured Rector'

########################################################################################################################
echo -e "${LOG_START}Configuring CI...${LOG_END}"
PROJECT_NAME="${PROJECT_NAME}" \
    envsubst '${PROJECT_NAME}' \
    < ../steps/step1010/Jenkinsfile \
    > Jenkinsfile
commit 'CI: Added Jenkinsfile'

########################################################################################################################
echo -e "${LOG_START}Fixing permissions...${LOG_END}"
fixPermissions

########################################################################################################################
echo -e "${LOG_START}Displaying the current git log...${LOG_END}"
git --no-pager log

echo -e "${LOG_START}Done!${LOG_END}"
