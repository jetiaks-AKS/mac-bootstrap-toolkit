# Mac Bootstrap Toolkit

Automated preparation and restoration of a macOS working environment.

**Current version: 2.0.0 Stable**

---

## Purpose

Mac Bootstrap Toolkit helps reproducibly prepare a macOS working environment.

The Toolkit can:

- analyze an existing environment;
- automatically generate its configuration;
- use that configuration to bootstrap a new Mac;
- check the current state of supported components;
- restore them when necessary.

The main idea of the project is to transfer not the entire system, but specifically the user's **working environment**.

---

## Project Status

Mac Bootstrap Toolkit is an independent hobby project created primarily as
a practical tool for quickly transferring a personal working environment to
a new Mac.

The Toolkit already fulfills its original purpose: it can discover an
existing working environment, generate its configuration, and use that
configuration to bootstrap a new Mac.

There is still plenty of room for further development, improvements and new
features. The project is therefore continuing to evolve beyond its original
goal.

Ideas, suggestions, feedback and improvements are welcome. However, this is
a personal project developed in my spare time, so there is no fixed support
schedule or expectation of continuous day-to-day maintenance.


## Main Workflow

```text
Existing Mac
     ↓
 Discovery
     ↓
Generated Configuration
     ↓
 Bootstrap
     ↓
Ready-to-Work Mac
````

Discovery automatically analyzes the existing environment and generates configuration that is then used by Bootstrap.

This approach allows the Toolkit to gradually evolve from a simple Bootstrap tool into a complete system for reproducible macOS working environments.

---

## Features

### Bootstrap

* Homebrew Packages;
* Homebrew Casks;
* App Store applications;
* Git;
* VS Code Extensions;
* VS Code Settings;
* macOS Settings;
* Workspace Folders;
* Git Repositories;
* Git Branch Restoration.

### Discovery

* Homebrew Packages;
* Homebrew Casks;
* Git Configuration;
* VS Code Extensions;
* VS Code Settings;
* macOS Settings;
* Workspace structure;
* Workspace Folders;
* Git Repositories;
* Workspace Inventory.

Discovery results are stored in:

```text
config/generated/
```

---

## Principles

* **Discovery First** — the existing environment is analyzed first instead of being described manually.
* **Generated Configuration** — Discovery results are used as configuration for Bootstrap.
* **Idempotent** — repeated runs should not perform unnecessary changes.
* **Verify After Apply** — the resulting state is checked again after changes are applied.
* **Self-Healing** — supported components can be automatically restored when necessary.
* **Quiet by Default** — standard output remains compact.
* **Verbose When Needed** — `--verbose` provides detailed information.
* **Modular Architecture** — functionality is divided into independent modules.

---

## CLI

Check the system:

```bash
./bootstrap.sh --check
```

Discover the current environment:

```bash
./bootstrap.sh --discover
```

Bootstrap the working environment:

```bash
./bootstrap.sh --bootstrap
```

Verbose output:

```bash
./bootstrap.sh --check --verbose
./bootstrap.sh --discover --verbose
./bootstrap.sh --bootstrap --verbose
```

Additional commands:

```bash
./bootstrap.sh --help
./bootstrap.sh --version
```

---

## Structure

```text
.
├── config/
│   └── generated/
├── docs/
├── modules/
├── scripts/
├── settings/
└── bootstrap.sh
```

The main Toolkit logic is located in `modules/`.

Automatically discovered configuration is stored in:

```text
config/generated/
```

---

## Implemented

### Core

* [x] Logging
* [x] Preflight Checks
* [x] Homebrew
* [x] Git
* [x] SSH
* [x] Terminal

### Bootstrap

* [x] Applications
* [x] VS Code
* [x] macOS Settings
* [x] Workspace Folders
* [x] Git Repository Restoration
* [x] Git Branch Restoration

### Discovery

* [x] Homebrew
* [x] Git
* [x] VS Code
* [x] macOS
* [x] Workspace
* [x] Generated Configuration
* [x] Workspace Inventory

### CLI

* [x] `--check`
* [x] `--discover`
* [x] `--bootstrap`
* [x] `--verbose`
* [x] `--help`
* [x] `--version`

---

## Project Development

Version 2.0.0 establishes a stable foundation for further development of the Toolkit.

The following architectural stages are planned:

```text
Discovery
     ↓
Generated Configuration
     ↓
Blueprint
     ↓
Verification
     ↓
Bootstrap
     ↓
Restore
```

Blueprint, Verification, Restore and AI Assistant are future development stages and are not part of the current stable functionality.

The detailed development plan is described in `ROADMAP.md`.

---

## Documentation

Project documentation is organized by purpose:

* `docs/getting-started/` — getting started and common usage scenarios.
* `docs/toolkit/` — Toolkit architecture and internals.
* `docs/macos/` — macOS documentation.
* `docs/git/` — Git and development workflows.
* `docs/blueprint/` — Blueprint materials.
* `docs/ideas/` — ideas and future development directions.

Main documents:

* `ROADMAP.md` — project development roadmap.
* `TODO.md` — current technical tasks.
* `CHANGELOG.md` — project change history.

---

## Status

| Parameter     | Value      |
| ------------- | ---------- |
| Status        | **Stable** |
| Version       | **2.0.0**  |
| Platform      | macOS      |
| Language      | Bash       |
| Architecture  | Modular    |
| Configuration | Generated  |
| License       | MIT        |

---

Mac Bootstrap Toolkit is evolving as a system for reproducible macOS working environments.

Version **2.0.0 Stable** establishes the stable foundation of the Toolkit:

**Discovery → Generated Configuration → Bootstrap**

This architecture serves as the foundation for the further development of the project.

```
