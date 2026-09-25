# Mac Bootstrap Toolkit

English | [Русский](README.ru.md)

A modular Bash toolkit for reproducibly preparing and restoring a macOS
working environment.

**Current version: 3.2.0 Stable**

## Overview

Mac Bootstrap Toolkit discovers supported parts of an existing Mac, stores
that state as local configuration, lets the user select a restoration scope,
previews the resulting changes, and applies them on a target Mac.

The project reconstructs supported parts of a working environment. It is not
a backup, Migration Assistant, or general user-data transfer tool.

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
- restricted SSH client configuration;
- VS Code extensions and settings;
- limited standalone Zsh `.zshrc` restoration;
- Workspace folders and Git repositories;
- macOS settings for Finder, Dock, Window Management, Keyboard, Trackpad, and
  Screenshots.

The exact configuration formats, supported macOS preferences, validation
rules, and restoration limits are documented in
[Configuration](docs/toolkit/CONFIGURATION.md).

## Quick Start

Choose the path that matches your task:

```bash
bs workflow                         # Discover, select, preview and apply on this Mac
bs capture                          # Create one private Bundle on the source Mac
bs restore /path/to/bundle.mbt       # Reconstruct on the new Mac
```

For a move between Macs, run `bs capture` on the old Mac, privately transfer
the resulting `.mbt` file, then run `bs restore /path/to/bundle.mbt` on the new
Mac. Afterwards, use `bs workflow` normally on the new Mac. Clone the Toolkit
repository on each Mac; before `bs` is installed, use `./bootstrap.sh --workflow`,
`./bootstrap.sh --capture`, or `./bootstrap.sh --restore /path/to/bundle.mbt`
from its root.

Applications are installed and Git repositories are cloned from remotes;
working trees and user files are not copied. Optional selected SSH identities
use an encrypted Secure Credentials payload. See
[Quick Start](docs/getting-started/QUICKSTART.md) for the steps and
[CLI](docs/toolkit/CLI.md) for advanced individual commands.

## Documentation

- [Documentation index](docs/README.md)
- [Quick Start](docs/getting-started/QUICKSTART.md)
- [Architecture](docs/toolkit/ARCHITECTURE.md)
- [Configuration](docs/toolkit/CONFIGURATION.md)
- [CLI](docs/toolkit/CLI.md)
- [Roadmap](ROADMAP.md)
- [Changelog](CHANGELOG.md)

## Project Status

Version 3.2.0 is the stable release; Capture/Restore is currently on `develop`
and remains unreleased. Aggregate Global Verification remains optional future
work.

See [ROADMAP.md](ROADMAP.md) for current development direction.

## Support

Mac Bootstrap Toolkit is free and open source. If the project saves you time,
you can support its continued development through a voluntary donation on
[Boosty](https://boosty.to/jetiaks/donate).

## License

Mac Bootstrap Toolkit is available under the [MIT License](LICENSE).
