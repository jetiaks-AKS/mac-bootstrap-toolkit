# Mac Bootstrap Toolkit Architecture

English | [Русский](ARCHITECTURE.ru.md)

## Purpose

Mac Bootstrap Toolkit is a modular Bash system for discovering and
reproducing supported parts of a macOS working environment. This document
defines the current architectural responsibilities and their planned
extension; implementation scheduling belongs in the Roadmap.

## Current architecture

The implemented architecture is:

```text
Current Mac
    ↓
Discovery
    ↓
Generated Configuration
    ↓
Blueprint
    ↓
Bootstrap
    ↓
Target Mac
```

Discovery records supported current state, Generated Configuration stores the
observed values, Blueprint selects the desired restoration scope, and
Bootstrap applies the selected supported values.

## State and responsibility model

Toolkit separates observed values from desired selection:

```text
Observed State
    ↓
Generated Configuration
    +
Blueprint Desired Selection
    ↓
Selected supported state
    ↓
Bootstrap
```

- **Observed State** is the supported state detected on the source Mac.
- **Generated Configuration** stores machine-specific observed values.
- **Blueprint** stores Desired Selection: categories and items included in the
  restoration scope.
- **Bootstrap** consumes generated values through that selection and applies
  the selected supported state.

Blueprint does not own, copy, or rewrite discovered values. Observed State and
Desired Selection remain separate responsibilities.

## Current architectural contracts

### Discovery

Discovery observes supported state without modifying that observed domain. Its
export lifecycle is:

```text
Collect → Validate → Serialize → Safe Publication
```

Generated output is replaced only after the new state has been collected,
validated, and serialized successfully. A handled collection, serialization,
or publication failure preserves the previous valid generated state.

Discovery is not a backup system: it records configuration and metadata but
does not copy user documents or repository contents.

### Generated Configuration

`config/generated/` contains private, local, machine-specific derived state and
is excluded from Git. Producer and consumer formats must remain compatible.

Application data uses simple formats, global Git state uses native
non-executable Git configuration, and sectioned Workspace repository data uses
the existing Configuration Engine. Git generated state is parsed as data and
must never be consumed through `source` or `eval`.

Most generated files publish independently. Workspace metadata in
`workspace.conf` also publishes independently, while `folders.conf`,
`repositories.conf`, `vscode-workspaces.conf`, and `inventory.conf` form one
grouped snapshot and publish together.

Generated state can contain personal paths, Git identity, repository URLs, and
editor settings, so it should be reviewed and transferred privately.

### Blueprint

Blueprint validates and stores Desired Selection in the private local
`config/blueprint.conf`. It selects discovered categories and items without
duplicating their values from Generated Configuration.

When Blueprint is absent, Bootstrap preserves the compatible legacy
all-inclusive behavior for the supported generated scope.

### Bootstrap

Bootstrap applies selected supported values through the current module-level
lifecycle:

```text
Check → Apply → Verify
```

This **Verify** is current local post-apply verification performed by a module
when the resulting state is observable with its existing mechanisms. It is not
the future aggregate Global Verification capability.

Bootstrap modules remain idempotent: they inspect current state, apply only
needed changes, and locally verify results where supported. Required generated
input is validated before mutation where applicable. Observation failure
remains distinct from legitimate absence or mismatch and must not be converted
into “apply required.” Unsafe existing state is reported rather than corrected
destructively.

Discovery of VS Code Workspace metadata and generation of
`vscode-workspaces.conf` are implemented. Bootstrap restoration of
`.code-workspace` is not implemented and is disconnected from production
Bootstrap orchestration.

### Core boundary

`modules/core/` provides shared output, logging, module lifecycle, preflight,
configuration, and common environment services. Domain-specific Discovery and
Bootstrap behavior remains outside Core.

## Planned architecture extension

The planned extension is:

```text
Discovery
    ↓
Generated Configuration
    ↓
Blueprint
    ↓
Dry-run / Preview
    ↓
Bootstrap
    ↓
Global Verification
```

Dry-run / Preview and Global Verification remain planned and unimplemented.

### Dry-run / Preview

Dry-run / Preview is a future non-mutating mode of the existing Bootstrap
model. It will show planned changes from the selected supported state. It is
not a configuration source or a separately required planning engine.

### Global Verification

Global Verification is a future post-Bootstrap capability that will evaluate
the resulting selected state and produce an aggregate confirmation. It is
distinct from the current local module-level Verify step and does not require
a separate complex engine to be defined in advance.

## Optional future directions

A separate Restore Engine and an AI Assistant remain optional directions, not
required stages of the architecture. They should be considered only if a clear
responsibility emerges that the established model cannot cover cleanly.

## Architecture and implementation status

This document defines architectural responsibilities and boundaries.
Implementation stages and release gates are maintained in
[ROADMAP.md](../../ROADMAP.md), near-term work in [TODO.md](../../TODO.md), and
completed release history in `CHANGELOG.md`.

Return to the [main README](../../README.md).
