# Documentation

Documentation for Mac Bootstrap Toolkit.

The documentation is intentionally kept compact. Detailed behavior should be
documented only where it has a clear and stable responsibility.

## Getting Started

- [Quick Start](getting-started/QUICKSTART.md) — installation and the main
  Discovery → Blueprint → Bootstrap workflow.

## Toolkit

- [Architecture](toolkit/ARCHITECTURE.md) — current architecture, component
  responsibilities, and planned architectural extensions.
- [Architecture — Russian](toolkit/ARCHITECTURE.ru.md) — Russian version of
  the architecture document.
- [Configuration](toolkit/CONFIGURATION.md) — Generated Configuration,
  Blueprint, configuration ownership, formats, and publication rules.
- [Output and Logging](toolkit/OUTPUT.md) — CLI output, logging, Summary, and
  status behavior.

## Development and Releases

- [Contributing](../CONTRIBUTING.md) — development workflow, change principles,
  commit conventions, and validation.
- [Release Process](git/RELEASE-PROCESS.md) — maintainer release procedure.
- [Roadmap](../ROADMAP.md) — implementation stages and planned development.
- [TODO](../TODO.md) — immediate technical backlog.
- [Changelog](../CHANGELOG.md) — completed release-visible changes.

## Project Direction

- [Vision](VISION.md) — long-term product direction and design principles.

## Documentation rules

Documentation should describe stable responsibilities rather than mirror every
source file or module.

When behavior changes:

- update Architecture only when architectural responsibilities or contracts
  change;
- update Configuration when configuration ownership or formats change;
- update Output and Logging when user-visible lifecycle or logging behavior
  changes;
- update Quick Start when the supported user workflow changes;
- update Roadmap or TODO when implementation status or near-term work changes;
- record completed release-visible changes in the Changelog.

Implementation details that are already clear from code and tests do not require
a separate documentation page.
