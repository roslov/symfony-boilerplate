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
| `steps/step0090` | AI agent support (`AGENTS.md`, `documentation.md`, `docs/*.md`, `.agents/skills/*`)      |
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

### Step 2: Render Templates Safely with `renderTemplate` and `replacePlaceholder`

Because `create-microservice.sh` `cd`s into `app/` before running provisioning steps, reference step files via
`../steps/stepXXXX/...`.

Always pass an explicit single-quoted variable whitelist to `renderTemplate` (which wraps `envsubst`) so shell
variables or PHP `$variables` in the template are not wiped out:

```bash
renderTemplate ../steps/step0038/Makefile Makefile '${PROJECT_NAME}'
```

When replacing a placeholder section inside `README.md` or `config/services.yaml`:

1. Use `sed -i` to replace the target lines with literal `\${REPLACE}`.
2. Call `replacePlaceholder <target_file> <snippet_file>` to substitute `${REPLACE}` with the snippet contents:

```bash
sed -i '/^Testing$/,/^\*\*TBD\*\*$/c\${REPLACE}' README.md
replacePlaceholder README.md ../steps/step0050/tests.md
```

### Step 3: Installing Packages and Updating `composer.json`

Use the container and Composer helper functions defined in `create-microservice.sh`:

- **`runInContainer <cmd> [args...]`**: Runs any command inside the `boilerplate` Docker container.
- **`requireWithContrib <args...>`**: Temporarily sets `extra.symfony.allow-contrib` to `true`, runs
  `composer require "$@"`, resets `allow-contrib` to `false`, and runs `composer update --lock`:
  ```bash
  requireWithContrib -W roslov/queue-bundle
  ```
- **`updateComposerJsonWithJq '<filter>'`**: Applies a `jq --indent 4` transformation to `composer.json`.
- **`updateComposerJsonWithPhp <<'PHP' ... PHP`**: Modifies `$composer` in `composer.json` via a clean heredoc PHP
  snippet.

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
