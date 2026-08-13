# Mac Bootstrap Toolkit Architecture

English | [Русский](ARCHITECTURE.ru.md)

Mac Bootstrap Toolkit is a modular Bash system for discovering and
reproducing supported parts of a macOS working environment.

## Current architecture

Version 2.0.1 implements this stable contract:

```text
Current Mac
    ↓
Discovery
    ↓
config/generated/
    ↓
Bootstrap
    ↓
Target Mac
```

### Discovery

Discovery reads supported state from the current Mac and exports it to
`config/generated/`. Its modules cover Homebrew, App Store applications,
global Git configuration, VS Code, selected macOS settings, and workspace
metadata.

Generated configuration is machine-specific local data and is excluded from
Git. Discovery is not a backup system: it records configuration and metadata,
but does not copy user documents or repository contents.

### Generated configuration

Generated files form the boundary between Discovery and Bootstrap. Simple
lists and shell-style configuration are used for application and Git data;
sectioned configuration is read through the Configuration Engine for workspace
repositories. Exporters and consumers must keep their formats compatible.

Because generated files can contain personal paths, Git identity, repository
URLs, and editor settings, they should be reviewed and transferred privately.

### Bootstrap

Bootstrap consumes generated configuration and applies supported state. Its
normal module lifecycle is:

```text
Check → Apply → Verify
```

Modules are intended to be idempotent: they first inspect existing state,
apply only needed changes, and verify the result where supported. The current
execution order is:

1. preflight checks;
2. Homebrew, Git, SSH, and Terminal checks;
3. workspace folders and Git repositories;
4. global Git configuration;
5. Homebrew formulae and casks;
6. App Store applications;
7. VS Code extensions and user settings;
8. Finder, Dock, keyboard, trackpad, and screenshot settings.

Workspace restoration creates missing directories and clones missing
repositories. For existing repositories it verifies `origin`; it only restores
a configured branch when tracked and staged changes are absent. Conflicts are
reported rather than resolved destructively.

### Core services

`modules/core/` provides shared infrastructure:

- compact and verbose output, module execution, statistics, and summary;
- per-run and latest logging with interruption handling;
- preflight checks;
- configuration parsing;
- common Homebrew, Git, SSH, and Terminal checks.

Domain-specific discovery or bootstrap behavior remains outside Core.

### Project layout

```text
bootstrap.sh                 CLI and orchestration
modules/core/                shared infrastructure
modules/discovery/           observed-state exporters
modules/bootstrap/           workspace bootstrap
modules/apps/                Homebrew and App Store consumers
modules/vscode/              VS Code consumers
modules/settings/macos/      macOS settings consumers
config/                      static Toolkit configuration
config/generated/            local machine-specific configuration
settings/                    static settings sources
scripts/                     supporting analysis/export scripts
docs/                        project documentation
```

## Planned architecture

The following stages describe future direction and are not implemented in
version 2.0.1:

```text
Observed State
    ↓
Blueprint
    ↓
Verification
    ↓
Bootstrap with Dry-run
    ↓
Restore
```

- **Dry-run** will preview Bootstrap actions without applying them.
- **Blueprint** will define desired state separately from discovered state.
- **Verification** will compare current and desired state.
- **Restore** will coordinate complete environment recovery and dependencies.
- **AI Assistant** is a planned layer for analysis, explanations, and guided
  workflows over these components.

Until those stages are implemented, Bootstrap reads generated observed state
directly. The current CLI has no `--dry-run` option.

Implementation status is maintained in [ROADMAP.md](../../ROADMAP.md), with
near-term work in [TODO.md](../../TODO.md).

Return to the [main README](../../README.md).
