# Mac Bootstrap Toolkit

English | [Русский](README.ru.md)

A modular Bash toolkit for reproducibly preparing and restoring a macOS
working environment.

**Current version: 3.1.0 Stable**

## Overview

Mac Bootstrap Toolkit discovers supported parts of an existing Mac, stores
that state as local configuration, lets the user select a restoration scope,
previews the resulting changes, and applies them on a target Mac.

The project reproduces a working environment rather than cloning an entire
operating system.

```text
Discovery → Generated Configuration → Blueprint → Preview → Bootstrap
```

- **Discovery** records supported current state in `config/generated/`.
- **Generated Configuration** is private, machine-specific derived data.
- **Blueprint** optionally selects which discovered components to restore.
- **Preview** inspects and reports selected changes without applying them.
- **Bootstrap** applies the selected supported state idempotently and verifies
  results where the current module can observe them.

Without a Blueprint, the full supported generated scope is processed.

## Capabilities

- Homebrew formulae and casks;
- App Store applications;
- global Git configuration;
- VS Code extensions and settings;
- Workspace folders and Git repositories;
- macOS settings for Finder, Dock, Window Management, Keyboard, Trackpad, and
  Screenshots.

The exact configuration formats, supported macOS preferences, validation
rules, and restoration limits are documented in
[Configuration](docs/toolkit/CONFIGURATION.md).

## Quick Start

Run the guided workflow from the repository root:

```bash
./bootstrap.sh --workflow
```

Or run individual modes:

```bash
./bootstrap.sh --check
./bootstrap.sh --discover
./bootstrap.sh --blueprint
./bootstrap.sh --dry-run
./bootstrap.sh --bootstrap
```

Use `--verbose` for additional diagnostics. Bootstrap can install the optional
`bs` launcher; complete operating instructions, transfer guidance, and safety
notes are in [Quick Start](docs/getting-started/QUICKSTART.md). CLI modes,
output, logging, exit statuses, and launcher behavior are described in
[CLI](docs/toolkit/CLI.md).

## Documentation

- [Documentation index](docs/README.md)
- [Quick Start](docs/getting-started/QUICKSTART.md)
- [Architecture](docs/toolkit/ARCHITECTURE.md)
- [Configuration](docs/toolkit/CONFIGURATION.md)
- [CLI](docs/toolkit/CLI.md)
- [Roadmap](ROADMAP.md)
- [Changelog](CHANGELOG.md)

## Project Status

Version 3.1.0 is stable. Preview is implemented; aggregate Global Verification
remains an optional future capability and is not required by the current
architecture.

See [ROADMAP.md](ROADMAP.md) for current development direction.

## Support

Mac Bootstrap Toolkit is free and open source. If the project saves you time,
you can support its continued development through a voluntary donation on
[Boosty](https://boosty.to/jetiaks/donate).

## License

Mac Bootstrap Toolkit is available under the [MIT License](LICENSE).
