Testing
-------

Tests are located in `tests` directory.
They are developed with [Codeception PHP Testing Framework](http://codeception.com/).

By default, there are such test suites:
- `Unit`
- `Functional`

Tests can be executed by running
```sh
codecept run
```
The command above will execute unit and functional tests. Unit tests are testing the system components, while functional
tests are for testing component integration.

### Running tests

To execute tests, do the following:
```sh
# Run all available tests
codecept run
# Run unit tests
codecept run Unit
# Run only unit and functional tests
codecept run Unit,Functional
```

### Creating new tests

To create a new test, run one of the following commands:
```sh
codecept g:test Unit UserTest
codecept g:cest Functional ExampleCest
```

### Code coverage support

By default, code coverage is disabled until you enable XDebug.
You can run your tests and collect coverage with the following command:
```sh
# Collect coverage for all tests
XDEBUG_MODE=coverage codecept run --coverage --coverage-html --coverage-xml
# Collect coverage only for unit tests
XDEBUG_MODE=coverage codecept run Unit --coverage --coverage-html --coverage-xml
# Collect coverage for unit and functional tests
XDEBUG_MODE=coverage codecept run Functional,Unit --coverage --coverage-html --coverage-xml
```
You can see code coverage output under the `tests/_output` directory.
