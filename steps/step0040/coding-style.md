Code quality check
------------------

To test how the code complies with coding style, syntax and how it is maintainable,
use commands below in the project root:

```sh
# Checks Composer dependencies, coding style and PHP syntax as a single command.
# It runs both coding style and syntax check, but does not do any fixes.
# It is run for the whole project.
# Also it can other checks — see the file for details
# Checks Composer dependencies, coding style, PHPStan rules, PHP syntax and others as a single command.
# It runs both coding style and syntax check, but does not do any fixes.
# It is run for the whole project.
# Also it can other checks — see the file for details
composer test:static
# Checks coding style.
# (Here and below you can replace `.` with different path or paths.)
composer phpcs .
# Fixes coding style
composer phpcbf .
# Checks PHP syntax
composer syntax .
```

If you are planning to integrate the code quality check with your IDE, use file `ruleset.xml` in the project’s root
folder.
