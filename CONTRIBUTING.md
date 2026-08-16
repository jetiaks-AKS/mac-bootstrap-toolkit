# Contributing

Thank you for contributing to Mac Bootstrap Toolkit.

## Workflow

- Start work from `develop`; it is the development branch.
- `main` contains stable releases only. Do not develop directly on `main`.
- Keep each commit to one logical task.
- Use an English commit message in the form `type: short description`, where
  `type` is `feat`, `fix`, `refactor`, `docs`, `style`, `chore`, or `release`.
- Do not commit generated configuration, logs, exports, environment files, or
  local temporary files.

Before editing, confirm that the working tree is understood and that local
`develop` matches `origin/develop`. Preserve unrelated local changes.

## Making changes

Keep changes small. Stable 2.0.1 uses:

```text
Discovery → config/generated/ → Bootstrap
```

The unreleased `develop` branch also implements the E2E-verified Blueprint
selection layer:

```text
Discovery → config/generated/ → Blueprint → Bootstrap
```

Discovery may write only its generated output and must not change the system.
Bootstrap changes must check current state, avoid unnecessary work, preserve
existing user data, and verify applied state where practical. Never add
destructive Git behavior such as reset, clean, force-push, or forced checkout.

Blueprint is implemented on `develop` but is not part of stable 2.0.1. Dry-run
and Verification remain planned and unimplemented. Keep release and development
status explicit when documenting these capabilities.

Update relevant documentation when behavior changes. Architecture changes
belong in `docs/toolkit/ARCHITECTURE.md`, near-term work in `TODO.md`, roadmap
status in `ROADMAP.md`, and completed user-visible changes in `CHANGELOG.md`.

## Validation

The repository has focused Blueprint regression harnesses, but not
comprehensive Toolkit coverage, a CI workflow, or a ShellCheck configuration:

```bash
scripts/test-blueprint.sh
scripts/test-blueprint-bootstrap.sh
scripts/test-blueprint-selector.sh
```

Run the relevant harnesses for Blueprint changes. For Bash changes, run at
minimum:

```bash
find modules scripts -type f -name '*.sh' -print0 | xargs -0 -n1 bash -n
bash -n bootstrap.sh
```

For changes that do not need to inspect or modify the local environment, the
safe CLI checks are:

```bash
./bootstrap.sh --help
./bootstrap.sh --version
```

Do not run `--check`, `--discover`, or `--bootstrap` casually: they have the
side effects described in the [Quick Start](docs/getting-started/QUICKSTART.md).

Before handing off a change, inspect:

```bash
git diff --check
git diff --stat
git status --short
```

Open contributions against `develop`. Release integration into `main`, version
changes, tags, and publishing follow the maintainer release process.
