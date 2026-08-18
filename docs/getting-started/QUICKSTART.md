# Quick Start

This guide covers the Mac Bootstrap Toolkit 3.0.0 workflow:

```text
Discovery
    ↓
Generated Configuration
    ↓
Blueprint
    ↓
Bootstrap
```

## Requirements

- macOS 15 or later
- Xcode Command Line Tools
- Internet connection
- Administrator account
- Git

Homebrew can be installed interactively by the Toolkit when it is missing.

Some optional components require their command-line tools:

- `mas` for Mac App Store applications
- `code` for VS Code extensions

---

## 1. Clone the repository

```bash
git clone git@github.com:jetiaks-AKS/mac-bootstrap-toolkit.git
cd mac-bootstrap-toolkit
```

Run Toolkit commands from the repository root.

To review the available CLI:

```bash
./bootstrap.sh --help
./bootstrap.sh --version
```

---

## 2. Check the Mac

Before Discovery or Bootstrap, check the current system:

```bash
./bootstrap.sh --check
```

For additional diagnostics:

```bash
./bootstrap.sh --check --verbose
```

The check validates the supported prerequisites and core environment before
continuing with Toolkit workflows.

---

## 3. Discover the source environment

Run Discovery on the Mac whose environment you want to reproduce:

```bash
./bootstrap.sh --discover
```

Discovery observes supported areas including:

- Homebrew packages and casks
- Mac App Store applications
- Git configuration
- VS Code extensions and settings
- Workspace folders and Git repositories
- VS Code Workspace metadata
- supported macOS settings

The observed machine-specific state is written locally to:

```text
config/generated/
```

Generated Configuration is excluded from Git and may contain personal paths,
Git identity, repository URLs, editor settings, and other machine-specific
information.

Review it before transferring it to another Mac.

Discovery does not install discovered applications or apply discovered system
settings. Its expected state-changing side effect is publication of local
Generated Configuration.

---

## 4. Select the restoration scope

After Discovery, create or edit the local Blueprint:

```bash
./bootstrap.sh --blueprint
```

Blueprint determines which supported parts of Generated Configuration should
be restored.

The interactive selector supports item-level selection for areas such as
applications, Homebrew packages and casks, VS Code extensions, Workspace
folders, and Git repositories, as well as category-level selection for
supported settings.

The resulting local selection is stored in:

```text
config/blueprint.conf
```

Blueprint contains selection state, not copies of discovered values.

Both `config/blueprint.conf` and `config/generated/` are local state and are
excluded from Git.

Without a Blueprint, Bootstrap preserves the supported all-inclusive behavior
for Generated Configuration.

---

## 5. Transfer the local state

On a different target Mac, clone the Toolkit repository and privately transfer
the reviewed local state required for restoration:

```text
config/generated/
config/blueprint.conf
```

Transfer `config/blueprint.conf` only when you want to preserve the same
selection. Without it, Bootstrap uses the supported all-inclusive behavior.

Do not commit machine-specific Generated Configuration or the private Blueprint
to the repository.

---

## 6. Bootstrap the target Mac

From the repository root on the target Mac:

```bash
./bootstrap.sh --bootstrap
```

For additional diagnostics:

```bash
./bootstrap.sh --bootstrap --verbose
```

Bootstrap combines Generated Configuration with the optional Blueprint
selection and restores supported state.

Depending on the selected scope, this can include:

- Homebrew packages and casks
- Mac App Store applications
- global Git configuration
- VS Code extensions and settings
- Workspace folders
- Git repositories and configured branches
- supported Finder, Dock, keyboard, trackpad, and screenshot settings

Bootstrap is designed to be idempotent: state that already matches the desired
configuration should not be changed unnecessarily.

Existing user state is protected where safe automatic convergence cannot be
guaranteed. Conflicts and unsafe conditions are reported instead of being
silently resolved through destructive operations.

VS Code Workspace metadata is discovered, but `.code-workspace` restoration is
not currently performed by Bootstrap.

---

## Logs and exit status

Toolkit keeps the latest run at:

```text
logs/latest.log
```

Historical logs are stored under:

```text
logs/history/
```

The final process status follows the common lifecycle:

- `0` — completed successfully
- `1` — completed with warnings
- `2` — completed with errors

Use `--verbose` when additional diagnostics are needed.

---

## Not implemented yet

The current workflow does not yet include:

- Dry-run / Preview
- aggregate post-Bootstrap Verification

These are planned extensions of the existing workflow rather than separate
configuration systems.

Other future capabilities are tracked in the project
[Roadmap](../../ROADMAP.md).

For architecture and configuration details, see:

- [Architecture](../toolkit/ARCHITECTURE.md)
- [Configuration](../toolkit/CONFIGURATION.md)

Return to the [main README](../../README.md).
