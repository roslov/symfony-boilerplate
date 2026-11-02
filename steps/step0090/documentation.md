Documentation
-------------

Architecture, requirements, security, and testing documentation:

* [`AGENTS.md`](AGENTS.md) — mandatory guidance for automated agents and contributors.
* [`docs/requirements.md`](docs/requirements.md) — product requirements, configuration variables, and queues.
* [`docs/architecture.md`](docs/architecture.md) — service architecture, layer responsibilities, and lifecycles.
* [`docs/security.md`](docs/security.md) — security goals, trust boundaries, and data classification.
* [`docs/testing.md`](docs/testing.md) — testing strategy, Codeception suites, and verification commands.
* [`docs/acceptance-criteria.md`](docs/acceptance-criteria.md) — release readiness and quality checklist.

All build and test dependencies are preconfigured in Docker. Agents and developers are not allowed to install anything
on the host machine or WSL and must use Docker containers only. Agents must not modify `Dockerfile` or files under
`.docker/` unless strictly requested. Never commit or push changes to git without an explicit user request.
