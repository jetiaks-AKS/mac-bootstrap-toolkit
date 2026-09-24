# Quick Start

This guide covers the current Mac Bootstrap Toolkit 3.2.0 workflow. Guided
Workflow orchestrates the same modes that remain available individually:

```text
Discovery
    ↓
Generated Configuration
    ↓
Blueprint
    ↓
Preview
    ↓
Bootstrap
```

For the guided path, run:

```bash
./bootstrap.sh --workflow
```

Workflow checks Generated Configuration, offers or requires Discovery, opens
the interactive Blueprint selector, and runs Preview automatically. Enter
`q` or `Q` at any Blueprint prompt, including Edit, to cancel without changing
the saved Blueprint; Guided Workflow then stops before Preview and Bootstrap.
If Preview reports errors, Workflow stops. If planned changes exist, Workflow
asks `Apply these changes with Bootstrap? [y/N]`. With zero planned changes it
reports `No changes to apply` and finishes without asking for Bootstrap,
preserving any Preview warning status.

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

The repository entrypoint remains canonical. The first setup run can use:

```bash
./bootstrap.sh --workflow
```

When Workflow reaches Bootstrap, or when `./bootstrap.sh --bootstrap` is run
directly, Bootstrap installs and verifies the optional short launcher. After
installation, `bs workflow`, `bs discover`, `bs blueprint`, `bs preview`,
`bs bootstrap`, and `bs check` dispatch to the matching `bootstrap.sh` modes
from any working directory. Discovery, Blueprint, Preview, and zero-change
Workflow do not install it. `./scripts/install-bs.sh` remains available for
manual installation or repair. It accepts an existing correct symlink and
refuses to overwrite another `bs`. Moving the repository invalidates the
symlink; remove it and rerun the installer from the new location.

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
- SSH client configuration
- VS Code extensions and settings
- standalone Zsh `.zshrc`
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

## 6. Preview the target changes

Inspect the selected target state before Bootstrap:

```bash
./bootstrap.sh --dry-run
```

Preview uses the same Blueprint selection, generated-input validation, and
production inspection logic as Bootstrap. It reports planned actions for
Applications, Git configuration, SSH client configuration, VS Code settings,
Zsh, Workspace, and macOS without mutating target state. Toolkit logging and
temporary validation files may still be written.

Planned changes do not count as warnings. The Preview Summary reports Modules
Inspected, Warnings, Errors, and Duration, and the process uses the common
status contract `0 / 1 / 2`.

---

## 7. Bootstrap the target Mac

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
- restricted SSH client configuration
- VS Code extensions and settings
- limited standalone Zsh `.zshrc` restoration
- Workspace folders
- Git repositories and configured branches
- supported Finder, Dock, Window Management, keyboard, trackpad, and screenshot
  settings

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

## Screenshot destination portability

Generated Screenshot `location` is the only destination source. Absolute paths
are preserved; leading `~/` resolves to the target user HOME. Other shell
expansions are rejected. An old `/Users/other-user/...` path is not rewritten.
Missing directories may be created inside HOME only; an outside-HOME destination
must already be writable and accessible. Preview also reports directory-only
changes without a process restart. See [Configuration](../toolkit/CONFIGURATION.md)
for the complete path policy.

## Not implemented yet

The current workflow does not yet include:

- aggregate post-Bootstrap Verification

This is a Future / Optional extension of the existing workflow.

Other future capabilities are tracked in the project
[Roadmap](../../ROADMAP.md).

For architecture and configuration details, see:

- [Architecture](../toolkit/ARCHITECTURE.md)
- [Configuration](../toolkit/CONFIGURATION.md)

Return to the [main README](../../README.md).
