# Quick Start

English | [Русский](QUICKSTART.ru.md)

This guide covers the implemented Mac Bootstrap Toolkit 2.0.1 workflow:

```text
Discovery → config/generated/ → Bootstrap
```

## Requirements

- macOS 15 or later;
- Xcode Command Line Tools;
- an internet connection;
- an administrator account;
- Git.

Homebrew can be installed interactively by the Toolkit when it is missing.
Some optional areas also require their command-line tools: `mas` for Mac App
Store applications and `code` for VS Code extensions.

## 1. Clone the repository

```bash
git clone git@github.com:jetiaks-AKS/mac-bootstrap-toolkit.git
cd mac-bootstrap-toolkit
```

Run every Toolkit command from the repository root. `bootstrap.sh` loads files
through relative paths.

## 2. Review the CLI

```bash
./bootstrap.sh --help
./bootstrap.sh --version
```

The implemented modes are `--check`, `--discover`, and `--bootstrap`.
`--verbose` can be combined with any of them.

## 3. Check the Mac

```bash
./bootstrap.sh --check
```

For diagnostic details:

```bash
./bootstrap.sh --check --verbose
```

The command checks internet access, Xcode Command Line Tools, the macOS
version, administrator privileges, Homebrew, Git, SSH, and Terminal. It asks
for administrator authentication and may offer to install Homebrew.

## 4. Discover the source environment

```bash
./bootstrap.sh --discover
```

Or use verbose output:

```bash
./bootstrap.sh --discover --verbose
```

Discovery inspects supported Homebrew, App Store, Git, VS Code, macOS settings,
and workspace state. It creates or overwrites machine-specific files in:

```text
config/generated/
```

That directory is excluded from Git. Treat its contents as sensitive local
configuration: it may include personal paths, Git identity, repository URLs,
and editor settings. Review the generated files and transfer them to a target
Mac through an appropriately private method.

Discovery does not install applications or apply system settings. Its expected
side effect is writing generated configuration; the common preflight and core
checks still run first and can request administrator authentication or offer to
install Homebrew.

## 5. Bootstrap the target environment

Place the reviewed generated configuration under `config/generated/` on the
target Mac, then run from the repository root:

```bash
./bootstrap.sh --bootstrap
```

For diagnostic details:

```bash
./bootstrap.sh --bootstrap --verbose
```

Bootstrap uses the generated configuration to:

- create missing workspace folders;
- clone missing Git repositories, verify origins, and restore configured
  branches only when existing repositories are clean;
- apply global Git configuration;
- install missing Homebrew formulae and casks;
- install configured App Store applications when `mas` is available;
- install VS Code extensions and apply VS Code user settings;
- apply supported Finder, Dock, keyboard, trackpad, and screenshot settings.

The VS Code settings module creates `settings.json.bootstrap.bak` before
replacing an existing, different settings file. Existing workspace directories
and repository remotes are not overwritten. Conflicts are reported for manual
attention.

## Logs and exit status

Runs write the latest log to `logs/latest.log` and timestamped history logs to
`logs/history/`. Both locations are excluded from Git.

The final process status is:

- `0` — success;
- `1` — completed with warnings;
- `2` — error.

## What is not available yet

Dry-run, Blueprint, Verification, Restore, and AI Assistant are planned future
work. In particular, `--dry-run` is not a supported option in version 2.0.1.
See the project [roadmap](../../ROADMAP.md) for status.

Return to the [main README](../../README.md).
