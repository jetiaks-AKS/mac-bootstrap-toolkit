# Mac Bootstrap Toolkit

English | [Русский](README.ru.md)

Mac Bootstrap Toolkit is a Bash toolkit for reproducibly preparing a macOS
development environment. It discovers supported parts of an existing Mac,
stores the observed state as local generated configuration, and uses that
configuration to bootstrap another Mac.

- **Current release:** 2.0.1 Stable
- **Platform:** macOS 15 or later
- **License:** MIT

## How it works

```text
Existing Mac
    ↓
Discovery
    ↓
config/generated/
    ↓
Bootstrap
    ↓
Ready-to-work Mac
```

Discovery writes machine-specific data to `config/generated/`. The directory
is intentionally excluded from Git. Bootstrap reads those generated files and
restores the supported parts of the environment.

Run all commands from the repository root because the entry point uses
relative paths.

## Current functionality

Discovery currently captures:

- Homebrew formulae and casks;
- Mac App Store applications;
- global Git configuration;
- VS Code extensions and user settings;
- Finder, Dock, keyboard, trackpad, and screenshot settings;
- top-level workspace folders, Git repository metadata, `.code-workspace`
  inventory, and workspace inventory.

Bootstrap currently supports:

- Homebrew setup, formulae, and casks;
- Mac App Store applications through `mas`;
- global Git configuration;
- workspace folder creation and cloning of missing Git repositories;
- repository origin checks and branch restoration for clean repositories;
- VS Code extensions and user settings;
- Finder, Dock, keyboard, trackpad, and screenshot settings.

Bootstrap modules are designed to check before applying changes and to skip
work when the requested state is already present.

## Quick start

Clone the repository and enter its root directory:

```bash
git clone git@github.com:jetiaks-AKS/mac-bootstrap-toolkit.git
cd mac-bootstrap-toolkit
```

Inspect the available commands:

```bash
./bootstrap.sh --help
./bootstrap.sh --version
```

Check prerequisites and core tools:

```bash
./bootstrap.sh --check
```

On the source Mac, generate local configuration:

```bash
./bootstrap.sh --discover
```

After making the generated configuration available on the target Mac, run:

```bash
./bootstrap.sh --bootstrap
```

Add `--verbose` to `--check`, `--discover`, or `--bootstrap` for diagnostic
output. See the [Quick Start](docs/getting-started/QUICKSTART.md) for the
complete first-run workflow.

## Safety

- Review generated configuration before using it on another Mac. It may
  contain personal paths, repository URLs, Git identity, and other
  machine-specific data; do not commit it.
- `--discover` reads the current environment but creates or overwrites files
  under `config/generated/`.
- `--check` performs preflight checks, requests administrator authentication,
  and may offer to install Homebrew if it is missing.
- `--bootstrap` changes the system. It may install software, update global Git
  configuration, create directories, clone repositories, copy VS Code settings
  after backing up an existing file, apply macOS defaults, and restart affected
  macOS services.
- Workspace bootstrap does not overwrite existing directories, change remotes,
  or switch branches in repositories with uncommitted tracked changes. It
  reports conflicts for manual attention.

## Project status and roadmap

Version 2.0.1 provides the stable current workflow:

```text
Discovery → Generated Configuration → Bootstrap
```

Dry-run, Blueprint, Verification, Restore, and AI Assistant are planned future
stages. They are not available in the current CLI or stable functionality.
Development status and future stages are tracked in [ROADMAP.md](ROADMAP.md);
near-term technical work is tracked in [TODO.md](TODO.md).

## Documentation

- [Quick Start](docs/getting-started/QUICKSTART.md)
- [Architecture](docs/toolkit/ARCHITECTURE.md)
- [Contribution guide](CONTRIBUTING.md)
- [Internal documentation index](docs/README.md) (Russian)
- [Changelog](CHANGELOG.md) (Russian)

## License

Mac Bootstrap Toolkit is available under the [MIT License](LICENSE).
