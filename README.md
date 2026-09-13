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
- immediate `q` / `Q` cancellation from every prompt, including Edit, without
  changing the saved Blueprint.

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

Run the guided flow interactively:

```bash
./bootstrap.sh --workflow
```

The first run still uses the canonical entrypoint:

```bash
./bootstrap.sh --workflow
```

When that Workflow reaches Bootstrap, or when `./bootstrap.sh --bootstrap` runs
directly, Bootstrap installs and verifies the short launcher automatically.
The repository entrypoint remains canonical. After installation, the launcher
can be called from any working directory:

```bash
bs workflow
bs discover
bs blueprint
bs preview
bs bootstrap
bs check
```

Discovery, Blueprint, Preview, and a Workflow that finishes after zero-change
Preview do not install `bs`. For manual installation or repair, run
`./scripts/install-bs.sh`. The installer uses the current Homebrew prefix when
available and refuses to replace an unrelated `bs` command or file. Moving the
repository later breaks the PATH symlink; remove the old symlink and rerun the
installer from the new location.

Reuse or refresh Generated Configuration, save Blueprint, and review mandatory
Preview. When Preview finds planned changes, Workflow asks for explicit
Bootstrap confirmation (default: No). Missing or invalid required input requires
Discovery; declining it or cancelling Blueprint stops cleanly. Preview warnings
allow confirmation when plans exist; errors block Bootstrap.
If Preview finds no changes to apply, Workflow finishes without prompting for
Bootstrap, preserving any warning status.
`--verbose` is supported. Each executed stage keeps its existing log and Summary.
Discovery retains its normal preflight and local configuration writes.


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
