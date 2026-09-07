# Changelog

All significant changes to **Mac Bootstrap Toolkit** are documented
in this file.

The format is based on the principles of **Keep a Changelog**.

---

## [Unreleased]

Current development after the **3.0.0 Stable** release.

### Added

* Completed Preview integration coverage through the real entrypoint and all
  production domain helpers, with external mutation spies, target snapshots,
  stable mixed-domain plans, warning/error propagation, and Summary log parity.

* Added non-mutating macOS Preview for Finder, Dock, Keyboard, Trackpad, and
  Screenshots. It reuses typed defaults validation and observation, reports
  current-to-desired or absent-to-desired changes, and plans category process
  restarts and the existing Screenshots directory creation without mutation.

* Added non-mutating Workspace Preview for selected folders and repositories.
  It reuses Workspace validation and inspection, reports folder creation,
  repository cloning, and eligible branch switching without mutation, and
  preserves warnings for dirty repositories, remote mismatches, and non-Git
  destinations.

* Added non-mutating Preview for Git configuration and VS Code settings. Git
  Preview reports every mismatched supported key after a complete inspection;
  VS Code settings Preview preserves the optional-source warning and reports an
  update only for an absent or byte-different target.

* Added non-mutating Preview for Homebrew formulae and casks, App Store
  applications, and VS Code extensions. Preview reuses Bootstrap validation,
  Blueprint selection, and presence inspection, including the existing cask
  reinstall decision, while reporting planned actions without installation or
  Bootstrap Changed-state accounting.

* Added the `--dry-run` Preview foundation with exclusive execution-mode
  parsing, selected-input validation, read-only preflight without `sudo`, and
  non-mutating Homebrew availability inspection. Preview has its own Summary
  semantics; domain-specific coverage is described above.

### Fixed

* Startup validation now suppresses normalized application records, keeping
  generated input out of normal Bootstrap and Preview terminal output while
  preserving validation status.

* Bootstrap now validates Blueprint and the required generated inputs of the
  selected scope before preflight and Core checks, blocking malformed input
  before Homebrew installation or target-state mutation. Homebrew availability
  now distinguishes an inspection error from confirmed absence, so an
  observation error cannot enter the installer path.

* `run_configuration()` now returns error 2 immediately when Apply fails and
  verifies only after successful Apply. Verify mismatch or observation failure
  returns error 2, while consumer-owned Changed state is preserved. The macOS
  Apply-failure guard is no longer needed by the generic lifecycle.

* Workspace folder restoration now distinguishes present, absent, and erroneous
  paths, creates only confirmed-absent folders, and verifies the resulting
  directory before success. Retained folder creation is recorded in Changed,
  and a folder error now blocks subsequent repository mutations.

* Workspace repository clone and branch restoration now report success only
  after local verification. Clone verifies the destination, usable Git worktree,
  and exact origin; checkout verifies the exact resulting branch. Mutation and
  verification failures return error 2 while retaining earlier Changed state.

* Workspace repository inspection now distinguishes dirty/mismatched state from
  filesystem and Git read errors. Failed worktree, origin, branch or clean-state
  observation blocks restore actions and propagates error 2 instead of becoming
  a checkout decision or an ordinary warning. Tracked/staged dirty-state policy
  and detached-HEAD restoration behavior are preserved.

* Workspace Bootstrap validates required selected paths and repository action
  fields before mutation, rejecting traversal outside HOME and incomplete inputs.
  Repository IDs with spaces and final records without a newline are preserved
  by line-oriented consumer parsing. Blueprint selection and clone/checkout
  lifecycle behavior are unchanged.

* VS Code settings Bootstrap validates source access before mutation, separates
  comparison errors from differences, and verifies byte equality before success.
  Settings and backups are staged before publication to avoid partial copies;
  retained directory, backup and settings changes are recorded even on later failure.

* Homebrew cask inspection now checks every reported artifact target instead of
  only the first. Invalid metadata blocks Apply; install/reinstall success is
  reported only after the same inspection verifies the resulting state.
  Successful mutations retain Changed state if verification or a later cask fails.

* App Store Bootstrap now checks exact numeric IDs instead of application-name
  substrings. App Store applications and VS Code extensions re-read inventory
  after successful installs and report success only after local verification.
  Observation or verification failure returns error 2; successful mutations
  remain recorded even if verification or a later installation fails.

* Homebrew casks, App Store applications, and VS Code extensions now validate
  their complete required generated input before observation or installation.
  Malformed or unreadable input returns error 2 without partial installation;
  empty Blueprint scopes retain their early successful skip. Generated formats
  are unchanged.

* Homebrew formula Bootstrap validates the complete generated list before
  installation, distinguishes inventory errors from absence, and verifies
  presence after successful installs. Changed state is recorded only after a
  successful install and remains recorded if a later install or verification
  fails; Bootstrap does not roll back earlier successful installations.

* Discovery Summary now reports modules processed, warnings, and errors instead
  of Bootstrap-oriented Installed / Skipped counts, in both terminal and log.
  Existing lifecycle accounting and Check / Bootstrap summaries are unchanged.

## [3.0.0] - 18.08.2026

Major release introducing **Blueprint** as the selection layer between
Generated Configuration and Bootstrap, together with reliability hardening
across Discovery, Bootstrap, Workspace, Git, Applications, and macOS Settings.

The current Toolkit workflow is:

```text
Discovery
    ↓
Generated Configuration
    ↓
Blueprint
    ↓
Bootstrap
````

Blueprint is optional. Without a local Blueprint, Bootstrap preserves the
legacy all-inclusive behavior.

### Added

#### Blueprint

* Added Blueprint as a separate selection layer between Generated Configuration
  and Bootstrap.
* Added local `config/blueprint.conf`.
* Added Blueprint parser and validation.
* Added item-level selection for:

  * Homebrew Packages;
  * Homebrew Casks;
  * App Store applications;
  * VS Code Extensions;
  * Workspace Folders;
  * Git Repositories.
* Added category-level selection for:

  * Git Configuration;
  * VS Code Settings;
  * Finder;
  * Dock;
  * Keyboard;
  * Trackpad;
  * Screenshots.
* Added interactive Blueprint creation and editing through `--blueprint`.
* Added All, None, and Edit modes for discovered item groups.
* Added numeric, comma-separated, space-separated, range, and mixed-range
  selection.
* Added pagination for larger item groups.
* Blueprint selector pages now display up to 20 items.
* Added loading and editing of an existing Blueprint.
* Added safe cancellation without modifying the existing Blueprint.
* Added `config/blueprint.example.conf`.
* Blueprint remains local and is excluded from Git.

#### Regression Testing

* Added focused regression harnesses for Blueprint parser and validation.
* Added focused regression harnesses for the interactive Blueprint selector.
* Added Blueprint-aware Bootstrap regression coverage.
* Added focused Application Discovery and Bootstrap consumer regression tests.
* Added Homebrew Discovery regression coverage.
* Added Git Generated State regression coverage.
* Added macOS Discovery and Bootstrap regression coverage.
* Added Workspace Discovery regression coverage.
* Added Workspace Bootstrap regression coverage.
* Added Workspace Folders regression coverage.

---

### Changed

#### Architecture

* The implemented Toolkit workflow is now:

```text
Discovery
    ↓
Generated Configuration
    ↓
Blueprint
    ↓
Bootstrap
```

* Generated Configuration remains the owner of machine-specific observed
  values.
* Blueprint owns Desired Selection and restoration scope.
* Blueprint does not copy, own, or rewrite discovered values.
* Bootstrap combines Blueprint selection with Generated Configuration values.
* Without Blueprint, Bootstrap preserves legacy all-inclusive processing.
* The existing module-level lifecycle remains `Check → Apply → Verify`.
* Global Verification remains a planned future capability.
* Dry-run / Preview remains planned and is not part of the 3.0.0 release.

#### Discovery

* Discovery exporters now use safe publication for Generated Configuration.
* New generated state is published only after successful observation,
  validation, and serialization.
* A handled observation, serialization, or publication failure preserves the
  previous valid generated file.
* Most generated files are published independently.
* Workspace derived files:

  * `folders.conf`;
  * `repositories.conf`;
  * `vscode-workspaces.conf`;
  * `inventory.conf`
    are published as one grouped snapshot.
* Observation failures are no longer automatically interpreted as component
  absence.

#### Git Configuration

* `config/generated/git.conf` now uses native Git config format.
* Supported generated Git values are read through
  `git config --file ... --no-includes`.
* Generated Git configuration is never executed through `source` or `eval`.
* Generated Git state is limited to supported global Git configuration keys.
* Git Generated State validation has been hardened.

#### Bootstrap

* Bootstrap now supports Blueprint-aware item and category filtering.
* Required generated input is validated before the first mutation where
  required by the selected scope.
* Observation semantics were hardened to distinguish:

  * present state;
  * absent state;
  * observation failure.
* Application consumers no longer interpret failed state checks as missing
  applications.
* Workspace Bootstrap validates required generated input before mutation.
* Existing Git repositories are validated before branch restoration.
* Repository remote URLs are verified against Generated Configuration.
* Branch restoration is performed only for clean repositories with matching
  remotes.
* Existing repository data and Git remotes are not rewritten when validation
  fails.
* macOS Bootstrap consumers now validate supported generated values by type.
* Added post-write verification for supported macOS Settings.
* Status propagation for `0 / 1 / 2` has been hardened.
* Bootstrap Summary now reflects Blueprint selection.
* Warning and error states no longer produce false success in the final
  lifecycle result.

#### Blueprint Selector

* Increased Blueprint selector page size from 10 to 20 items.
* Global item numbering is preserved across pages.
* Next and Previous navigation remains available for larger lists.
* Existing checkbox state is preserved when editing a Blueprint.

---

### Fixed

#### Discovery

* Fixed loss of previous valid Generated Configuration after handled Discovery
  failures.
* Fixed unsafe publication paths where incomplete observed state could replace
  previously valid generated state.
* Fixed handling of observation failures that could otherwise be interpreted
  as empty state.

#### Applications

* Fixed Application consumers treating failed installed-state checks as
  application absence.
* Fixed unsafe apply decisions caused by ambiguous observation results.

#### Git Configuration

* Fixed validation of malformed or unsupported Git Generated State.
* Fixed Git configuration read and apply error handling.
* Fixed unsafe interpretation of generated Git configuration.

#### Workspace

* Fixed Workspace Bootstrap validation so missing, unreadable, or malformed
  required generated input fails before the first mutation.
* Fixed repository validation and branch restoration warning propagation.
* Existing repositories with mismatching remotes are left unchanged.
* Repositories with uncommitted changes are not switched to another branch.
* Processing continues for remaining repositories when an individual
  repository requires manual attention.

#### macOS Settings

* Fixed validation of generated macOS values before apply.
* Fixed handling of unsupported or malformed typed values.
* Added verification of supported settings after write.
* Fixed cases where an apply operation could report success without confirming
  the resulting state.

#### Lifecycle and Summary

* Fixed propagation of warning and error statuses through Bootstrap lifecycle.
* Fixed false-success final Bootstrap results.
* Fixed Summary behavior so warning and error conditions are reflected
  correctly.

---

### Documentation

* Architecture documentation was aligned with the implemented
  Discovery → Generated Configuration → Blueprint → Bootstrap model.
* Configuration documentation was aligned with Observed State, Desired
  Selection, Generated Configuration, and Blueprint ownership.
* The distinction between local module Verify and planned global Verification
  was clarified.
* CLI Output and Logging documentation was consolidated.
* Quick Start was updated to the current supported workflow.
* Project documentation was simplified by removing obsolete and duplicated
  documents.
* Vision was updated while preserving the long-term project direction.
* Roadmap and TODO were aligned with the implemented 3.0.0 state.
* Module-level documentation was aligned with current production behavior.
* VS Code Workspace metadata Discovery remains implemented, while
  `.code-workspace` restoration remains outside production Bootstrap
  orchestration.

---

## [2.0.1] - 13.08.2026

Stabilization release after **2.0.0 Stable**.

### Added

#### Logging

* Added support for separate history log files for each Toolkit mode.
* Logs now automatically receive a prefix depending on the mode:

  * `bootstrap-YYYY-MM-DD_HH-MM-SS.log`
  * `check-YYYY-MM-DD_HH-MM-SS.log`
  * `discover-YYYY-MM-DD_HH-MM-SS.log`
* Added a unified `logs/latest.log` containing the latest Toolkit run.
* Added a timestamp to each log-file entry.
* Added handling of Toolkit interruption through `INT` and `TERM`.
* When Toolkit is interrupted, the log is correctly closed with the
  `Interrupted` status.
* Added protection against closing Logger more than once.

#### Module Lifecycle Logging

* Added logging for the start of each module execution.
* Added logging for each module execution result.
* Added logging of the `MODULE_CHANGED` state.
* Added recording of the following results:

  * `SUCCESS`
  * `WARNING`
  * `ERROR`
  * `UNKNOWN`
* Added equivalent logging for configuration modules.

#### Configuration

* Added a policy excluding `config/generated/` from Git.
* Generated Configuration is now treated as machine-specific configuration.
* Generated Configuration continues to be used locally for
  Discovery → Bootstrap, but must not be included in the public repository.

---

### Changed

#### Logging

* Logger is now initialized before the first informational Toolkit message.
* Mode is determined centrally for all supported modes:

  * `Check`
  * `Bootstrap`
  * `Discovery`
* Improved separation between Compact and Verbose Output.
* Detailed output continues to be controlled through `detail()`.
* Logger shutdown is centralized through `close_logger()`.
* Summary and final execution parameters are written to both history-log and
  `latest.log`.

#### Module Lifecycle

* `run_module()` is now centrally responsible for:

  * running the module;
  * counting checked modules;
  * determining state changes;
  * counting Installed / Skipped;
  * handling Warning / Error;
  * logging the result.
* `run_configuration()` now follows the same module lifecycle principle.
* Module Lifecycle logging no longer depends on an individual module.

#### Configuration

* Local machine-specific Generated Configuration is no longer part of the
  public Git state of the project.
* Git configuration was cleaned of personal user values:

  * `GIT_USER_NAME`
  * `GIT_USER_EMAIL`
* The public version of `config/git.conf` no longer contains personal Git
  identity settings.

---

### Fixed

#### Logging

* Fixed history-log creation for `--check`.
* Fixed history-log creation for `--discover`.
* Fixed history-log creation for `--bootstrap`.
* Fixed updating `logs/latest.log` after Toolkit completion.
* Fixed logging shutdown when the process is interrupted.
* Fixed the absence of a unified completion status in an interrupted log.
* Fixed Logger initialization before the first `info()` call.

#### Module Lifecycle

* Fixed the absence of unified result logging in `run_module()`.
* Fixed missing `MODULE_CHANGED` logging for modules.
* Fixed handling of an unknown module return code.
* Fixed result logging in `run_configuration()`.
* Fixed consistency of Installed / Skipped / Warnings / Errors statistics.

#### Workspace

* Fixed a situation where Bootstrap displayed Git branch mismatch warnings
  after switching the working project from `feature/mac-blueprint` to
  `develop`.
* Generated Workspace Configuration now correctly reflects the current working
  branch after running Discovery.
* Bootstrap continues processing remaining repositories when an individual
  repository requires manual attention and finishes Workspace with a warning.
* Missing or unreadable Workspace configuration now correctly returns a
  warning.
* Failure to create a Workspace folder now returns an error.

#### Exit Codes

* CLI now returns the final execution status:

  * `0` — success;
  * `1` — warning;
  * `2` — error.
* Error has priority over warning in the final Toolkit status.
* A preflight error now terminates Toolkit with exit code `2`.

#### Bootstrap Apply

* Git configuration now checks apply errors and the result of final
  configuration verification.
* Applying VS Code Settings now reports errors when creating the directory,
  backing up settings, or copying settings.

---

### Documentation

* Project documentation was aligned with the current architecture after the
  2.0.0 release.
* Documented that `config/generated/` contains machine-specific data and must
  not be included in the public repository.
* Documented the current model:
  **Discovery → Generated Configuration → Bootstrap**.
* Documented the separation between the current Toolkit implementation and
  future architectural stages.
* Added the implementation plan for a separate **Dry-run Mode**.
* Dry-run is considered the next stage before further development of the
  Blueprint approach.
* Documented the need for further Summary improvements for `--discover` mode.

---

## [2.0.0] - 09.08.2026

First stable Toolkit version based on the
**Discovery → Generated Configuration → Bootstrap** architecture.

### Added

#### Discovery Engine

* Added a complete Discovery Engine.
* Added automatic analysis of the current macOS working environment.
* Added discovery of Homebrew Packages and Casks.
* Added discovery of App Store applications.
* Added Git Configuration export.
* Added discovery of VS Code Extensions and Settings.
* Added Workspace structure discovery.
* Added discovery of Git Repositories and their metadata.
* Added Workspace Inventory.
* Added automatic configuration generation in `config/generated/`.

#### Workspace Bootstrap

* Added Workspace Bootstrap.
* Added Workspace structure restoration.
* Added Git Repository restoration.
* Added Remote URL verification.
* Added current Git branch verification.
* Added working Git branch restoration.
* Added Workspace Bootstrap integration with Generated Configuration.

#### Configuration

* Added a unified Configuration Engine.
* Bootstrap was migrated to use Generated Configuration.
* Removed duplication of user settings between Discovery and Bootstrap.
* Established the principle:

```text
Discovery
    ↓
Generated Configuration
    ↓
Bootstrap
```

#### CLI & Output

* Added a complete `--verbose` mode.
* Added compact output mode by default.
* Added a unified detailed-output mechanism through `detail()`.
* Discovery displays discovered objects in Verbose Mode.
* Added information about generated configuration files being created.
* Summary was adapted to the Toolkit execution mode.

---

### Changed

#### Architecture

* Toolkit moved from primarily manual configuration to the
  **Discovery → Generated Configuration → Bootstrap** model.
* Generated Configuration became the primary data source for Bootstrap.
* Workspace was separated into dedicated Discovery and Bootstrap areas.
* macOS Settings configuration was migrated to Generated Configuration.
* Documentation was revised to reflect the target project architecture.

#### Output

* Unified Compact and Verbose Mode behavior.
* Discovery modules use a unified informational message format.
* Removed unnecessary output duplication.
* Summary now correctly reflects the execution mode:
  Discovery, Bootstrap, or Check.

---

### Fixed

* Fixed App Store Discovery format in Generated Configuration.
* Fixed App Store application display in Verbose Mode.
* Fixed Verbose Output for VS Code Discovery.
* Fixed Verbose Output for Workspace Discovery.
* Fixed repeated Dock Discovery import.
* Fixed minor Workspace Discovery issues.
* Fixed general Summary text for different Toolkit modes.
* Fixed Generated Configuration compatibility with the format used by
  Bootstrap.

---

### Documentation

* Reworked the main project README.
* Updated architecture documentation.
* Updated ROADMAP.
* Updated TODO.
* Documentation was separated by purpose.
* Documented the target Toolkit development model.
* Documented the separation between the current implementation and future
  architectural stages.

---

## [1.1.0] - 04.08.2026

### Added

#### Core

* Added modular Toolkit architecture.
* Added unified logging system (`INFO`, `OK`, `WARN`, `ERROR`).
* Added check mode (`--check`).
* Added Bootstrap mode (`--bootstrap`).
* Added `--help`.
* Added `--version`.
* Added Toolkit startup screen displaying version and operating mode.

#### Homebrew

* Automatic Homebrew installation.
* Installed Homebrew verification.
* Automatic installation of CLI packages from the configuration file.
* Automatic installation of GUI applications (Casks) from the configuration
  file.
* Support for `brew install --cask --adopt` for existing applications.
* Added automatic Homebrew Cask restoration.
* Added result verification after installation (Verify After Apply).

#### Git

* Git installation verification.
* Automatic Git configuration.

#### SSH

* SSH configuration verification.

#### Terminal

* Terminal readiness verification.

#### App Store

* Added Mac App Store support through `mas`.
* Automatic application installation from `config/appstore.conf`.
* Verification of already installed applications before installation.

#### VS Code

* VS Code CLI (`code`) availability verification.
* Automatic extension installation from `config/vscode-extensions.conf`.
* Verification of already installed extensions.
* Automatic installation of missing extensions only.
* Automatic application of `settings.json`.
* Backup of existing VS Code settings.
* Verification that settings are current before applying them.

#### macOS

* Added modular Finder configuration.
* Added modular Dock configuration.
* Added modular Keyboard configuration.
* Added modular Trackpad configuration.
* Added modular Screenshots configuration.
* Added idempotent verification of current settings before applying changes.

#### Configuration

* Added configuration files:

  * `brew-packages.conf`
  * `brew-casks.conf`
  * `appstore.conf`
  * `vscode-extensions.conf`
* Added `settings/` directory.
* Added VS Code settings templates.

#### Project

* Added unified project structure.
* Added support for separate modules.
* Added separation into:

  * `modules`
  * `config`
  * `settings`
* Added `TODO.md`.
* Added `macos.sh` module.
* Added macOS settings export scripts.
* Added macOS settings analysis scripts.

#### Output

* Added `--verbose` mode.
* Added compact output mode by default.
* Added detailed output support (`detail()`).
* Added Quiet Mode for installation operations.
* Added final Summary with extended statistics.

---

### Changed

* Completely reworked the Toolkit command-line interface.
* Unified the style of all Toolkit modules.
* Unified function naming.
* Unified the `MODULE_CHANGED` principle.
* Significantly reduced Toolkit output volume.
* Implemented Compact / Verbose modes.
* All install modules were migrated to Quiet Mode.
* Improved project structure.
* Improved code readability.
* Updated project documentation.
* Toolkit moved to stable version `1.1.0`.

---

### Fixed

* Fixed Summary statistics calculation.
* Fixed changed-module detection logic.
* Fixed Homebrew Cask handling after manually removing applications.
* Fixed automatic restoration of missing Homebrew Casks.
* Fixed Homebrew Cask installation result verification.
* Fixed App Store application installation logic.
* Fixed VS Code extension verification logic.
* Fixed VS Code settings application logic.
* Fixed Finder checks.
* Fixed Dock checks.
* Fixed minor Bootstrap issues.

---

## [1.0.0] - 03.08.2026

First stable release of Mac Bootstrap Toolkit.

### Added

#### Core

- Added the initial modular Toolkit architecture.
- Added a unified status system using `INFO`, `OK`, `WARN`, and `ERROR`.
- Added system check mode (`--check`).
- Added full Bootstrap mode (`--bootstrap`).
- Added `--help`.
- Added `--version`.

#### Preflight

- Added Internet connectivity checks.
- Added Xcode Command Line Tools checks.
- Added macOS version compatibility checks.
- Added administrator privilege checks.

#### Homebrew

- Added Homebrew availability checks.
- Added automatic Homebrew installation.
- Added Homebrew package installation.
- Added Homebrew Cask installation.

#### Git

- Added Git installation checks.
- Added Git configuration checks.
- Added automatic Git configuration.

#### SSH

- Added SSH configuration checks.

#### Terminal

- Added Terminal readiness checks.

#### App Store

- Added App Store application installation through `mas`.
- Added checks for already installed App Store applications.

#### VS Code

- Added VS Code extension installation.
- Added `settings.json` application.
- Added backup of existing VS Code settings.
- Added checks for already current VS Code settings.

#### macOS

- Added Finder configuration.
- Added Dock configuration.
- Added Keyboard configuration.
- Added Trackpad configuration.
- Added Screenshots configuration.
- Added idempotent application of supported macOS settings.

### Changed

- Finalized the initial Bootstrap framework.
- Standardized the Bootstrap modules in English.
- Established the first stable modular project structure.
- Established idempotent configuration as a core Toolkit principle.

### Documentation

- Finalized the Roadmap for the first stable release.
- Updated Quick Start requirements for supported macOS, Internet access, and
  administrator privileges.
- Marked version 1.0.0 as the first stable Mac Bootstrap Toolkit release.
