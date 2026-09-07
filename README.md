# Mac Bootstrap Toolkit

English | [Русский](README.ru.md)

A modular Bash toolkit for reproducibly preparing and restoring a macOS
working environment.

**Current version: 3.1.0 Stable**

---

## Overview

Mac Bootstrap Toolkit can:

- discover supported components of an existing macOS environment;
- generate machine-specific configuration automatically;
- optionally select which discovered components should be restored;
- bootstrap the selected environment on another Mac;
- verify supported state before and after applying changes.

The project focuses on reproducing the **user working environment**, rather
than cloning the entire operating system.

---

## Workflow

```text
Existing Mac
     ↓
 Discovery
     ↓
Generated Configuration
     ↓
 Blueprint
     ↓
 Bootstrap
     ↓
Ready-to-Work Mac
```

Discovery captures the current environment in `config/generated/`.

Blueprint is an optional local selection layer that controls which discovered
components Bootstrap should process. Without a Blueprint, Bootstrap processes
the full supported scope.

---

## Features

### Discovery

- Homebrew Packages and Casks
- App Store applications
- Git Configuration
- VS Code Extensions and Settings
- macOS Settings
- Workspace structure and Git Repositories

### Blueprint

- interactive component selection;
- item-level and category-level filtering;
- editing of existing selections;
- safe cancellation without changing the saved Blueprint.

### Bootstrap

- Applications
- Git Configuration
- VS Code Extensions and Settings
- macOS Settings
- Workspace Folders
- Git Repository and Branch restoration

Toolkit operations are designed to be idempotent and verify supported state
before and after changes where applicable.

### Preview

- non-mutating `--dry-run` inspection for Applications, Git configuration,
  VS Code settings, Workspace, and macOS;
- Blueprint-aware planned actions using the same validation and inspection
  logic as Bootstrap;
- Summary reporting for inspected modules, warnings, errors, and duration.

---

## Quick Start

Check the system:

```bash
./bootstrap.sh --check
```

Discover the current environment:

```bash
./bootstrap.sh --discover
```

Optionally create or edit a Blueprint:

```bash
./bootstrap.sh --blueprint
```

Restore the environment:

```bash
./bootstrap.sh --bootstrap
```

Preview the selected changes without modifying target state:

```bash
./bootstrap.sh --dry-run
```

Use `--verbose` with Check, Discovery, or Bootstrap for detailed output.

See [Quick Start](docs/getting-started/QUICKSTART.md) for the complete workflow.

---

## Documentation

- [Quick Start](docs/getting-started/QUICKSTART.md)
- [Architecture](docs/toolkit/ARCHITECTURE.md)
- [Configuration](docs/toolkit/CONFIGURATION.md)
- [CLI](docs/toolkit/CLI.md)
- [Roadmap](ROADMAP.md)
- [Changelog](CHANGELOG.md)

---

## Project Status

**3.1.0 Stable**

Current architecture:

```text
Discovery → Generated Configuration → Blueprint → Bootstrap
```

Dry-run / Preview is included in 3.1.0. Global Verification remains a planned
future capability.

See [ROADMAP.md](ROADMAP.md) for further development.

---

## Support

Mac Bootstrap Toolkit is free and open source.

If the project saves you time and you would like to support its continued
development, you can make a voluntary donation via
[Boosty](https://boosty.to/jetiaks/donate).

---

## License

Mac Bootstrap Toolkit is available under the [MIT License](LICENSE).
