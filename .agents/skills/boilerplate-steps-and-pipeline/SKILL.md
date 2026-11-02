---
name: boilerplate-steps-and-pipeline
description: >-
  Add, modify, or reorder provisioning steps in `steps/stepXXXX/` and `create-microservice.sh`
  for the Symfony Microservice Boilerplate. Use when introducing new boilerplate files,
  updating template variable substitution (`envsubst`), or modifying the `[init]` commit sequence.
---

# Boilerplate Steps and Pipeline Workflow

This skill guides the creation and modification of provisioning steps under `steps/` and orchestration stages in
`create-microservice.sh`.

## Step Directory Naming & Ordering Convention

Provisioning templates live in numbered directories under `steps/` corresponding to their execution order in
`create-microservice.sh`:

| Step Folder      | Purpose                                                                                  |
|------------------|------------------------------------------------------------------------------------------|
| `steps/step0010` | `.gitignore` IDE patterns prepended to Symfony's `.gitignore`                            |
| `steps/step0020` | `.editorconfig` and `.gitattributes`                                                     |
| `steps/step0030` | Initial `README.md` template rendered with `envsubst`                                    |
| `steps/step0038` | Host development `Makefile` rendered with `${PROJECT_NAME}`                              |
| `steps/step0040` | PHPCS `ruleset.xml` (`roslov/psr12ext`), `coding-style.md`, and `faq.md`                 |
| `steps/step0045` | `monolog.yaml` with `rotating_file` (`dev`/`test`) and stderr JSON (`prod`)              |
| `steps/step0050` | Codeception config (`codeception.yml`), `tests.md`, `ExampleTest.php`, `ExampleCest.php` |
| `steps/step0060` | PHPStan stub (`stubs/CodeceptionExample.stub`)                                           |
| `steps/step0070` | `roslov_queue.yaml`, `old_sound_rabbit_mq.yaml`, `parameters.yaml`, `ExampleConsumer`    |
| `steps/step0080` | `rector.php` configuration                                                               |
| `steps/step1010` | Declarative `Jenkinsfile` rendered with `${PROJECT_NAME}`                                |

When inserting a new step between existing steps, choose an intermediate number (for example, `step0065` between
`step0060` and `step0070`) to preserve chronological ordering.

---

## Step-by-Step Guide: Adding or Modifying a Provisioning Step

### Step 1: Place Template Files in `steps/stepXXXX/`

- Store static files or `envsubst` templates inside `steps/stepXXXX/`.
- If a step copies a directory tree directly into `./app`, place those files inside `steps/stepXXXX/project/` (as done
  in `steps/step0070/project/`).
- Ensure all PHP files include `declare(strict_types=1);` and complete PHPDoc doc blocks so they pass PHPCS, PHPStan
  (`level: max`), and Rector.

### Step 2: Render Templates Safely with `envsubst`

Because `create-microservice.sh` `cd`s into `app/` at line 75, reference step files via `../steps/stepXXXX/...`.

Always pass an explicit single-quoted variable whitelist to `envsubst` so shell variables or PHP `$variables` in the
template are not wiped out:

```bash
PROJECT_NAME="${PROJECT_NAME}" \
    envsubst '${PROJECT_NAME}' \
    < ../steps/step0038/Makefile \
    > Makefile
```

When replacing a placeholder section inside `README.md` or `config/services.yaml`:

1. Use `sed -i` to replace the target lines with literal `\${REPLACE}`.
2. Run `REPLACE="$(cat ../steps/stepXXXX/snippet.md)" envsubst '${REPLACE}' < file > file2 && rm file && mv file2 file`.

### Step 3: Installing Symfony Flex Contrib Recipes

By default, `extra.symfony.allow-contrib` is set to `false`. When requiring a package that needs a contrib recipe or
when Composer prompts should be avoided during installation, temporarily enable `allow-contrib` and disable it
afterward:

```bash
docker compose run --rm boilerplate composer config extra.symfony.allow-contrib true --json
docker compose run --rm boilerplate composer require -W vendor/package
docker compose run --rm boilerplate composer config extra.symfony.allow-contrib false --json
docker compose run --rm boilerplate composer update --lock
```

### Step 4: Normalize, Fix, Validate, and Commit

At the end of the provisioning block in `create-microservice.sh`:

```bash
# 1. If composer.json was modified, bump and normalize it:
normalizeComposer

# 2. If PHP/YAML/config files were modified (after step0040), run Rector, PHPCBF, test:static, and test:unit:
fixAndValidateFiles

# 3. Commit the stage with an `[init]` prefix:
commit 'Added <feature description>'
```

---

## Verification

1. Check syntax:
   ```bash
   bash -n create-microservice.sh
   ```
2. If testing against `./app`, apply the step or run `./create-microservice.sh` and verify `git -C app log --oneline`
   and `docker compose run --rm boilerplate composer test`.

---

## Skill Maintenance & Self-Enforcement

Whenever adding, removing, or renumbering step folders under `steps/` or modifying helper functions in
`create-microservice.sh`, update this skill file (`.agents/skills/boilerplate-steps-and-pipeline/SKILL.md`).
