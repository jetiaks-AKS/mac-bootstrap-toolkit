# Release Process

Procedure for preparing and publishing a new stable version of
**Mac Bootstrap Toolkit**.

The release process publishes an already completed and validated state of the
project. It must not introduce new functionality during release preparation.

---

# 1. Complete Development

Before starting the release process, make sure that:

- the planned release scope is complete;
- required regression tests have passed;
- required manual validation has been completed;
- there are no known release-blocking issues;
- Toolkit behavior and documentation reflect the intended release state.

Once final release preparation begins, avoid expanding the release scope unless
a release blocker must be fixed.

---

# 2. Update Release Documentation

Review and update release-visible documentation where required:

- `README.md`
- `README.ru.md`
- `CHANGELOG.md`
- `ROADMAP.md`
- `docs/getting-started/QUICKSTART.md`

Update other documentation only when the release changes the responsibility or
contract documented there.

Do not update documentation merely because an implementation file changed.

---

# 3. Verify Release History

Fetch the latest remote state:

```bash
git fetch origin
```

Verify that the stable history from `main` is already contained in `develop`:

```bash
git merge-base --is-ancestor origin/main develop
echo $?
```

Exit code `0` means that `origin/main` is an ancestor of `develop`.

If `main` contains release history that is not present in `develop`, integrate
that history into `develop` before continuing.

Do not rewrite published stable history to make the graph appear linear.

---

# 4. Update Toolkit Version

Update:

```text
config/toolkit.conf
```

For example:

```text
TOOLKIT_VERSION="3.0.0"
```

The Toolkit version must match the version being prepared for release.

---

# 5. Final Release Validation

The complete functional release validation must already have been performed
before publication.

At the release gate, verify the repository and release state:

```bash
git diff --check
git status
```

Review the final changes when necessary:

```bash
git diff
git diff --stat
```

Confirm that:

- release documentation is final;
- Toolkit version is correct;
- no unintended files are included;
- no release blocker remains.

Do not repeat destructive or unnecessary production workflows solely for the
purpose of creating the release commit if their required validation has already
been completed.

---

# 6. Create the Release Commit

Stage the intended release changes:

```bash
git add <release-files>
```

Review the staged state:

```bash
git diff --cached --check
git diff --cached --stat
git status
```

Create the release commit:

```bash
git commit -m "release: version <version>"
```

For example:

```bash
git commit -m "release: version 3.0.0"
```

Push the completed `develop` state:

```bash
git push origin develop
```

Before proceeding, the working tree must be clean.

---

# 7. Merge `develop` into `main`

Switch to `main`:

```bash
git checkout main
```

Synchronize it with the remote stable branch:

```bash
git pull --ff-only origin main
```

Merge the prepared release:

```bash
git merge --no-ff develop
```

The merge must contain the already prepared release state. Do not make
unrelated release changes directly on `main`.

---

# 8. Verify and Publish `main`

Verify the merged state:

```bash
git status
git log -3 --oneline --decorate
```

Confirm that:

- the working tree is clean;
- the expected release commit is present;
- the Toolkit version is correct;
- the release documentation is present.

Publish `main`:

```bash
git push origin main
```

---

# 9. Create the Release Tag

Create an annotated tag on the published release state:

```bash
git tag -a v<version> -m "Mac Bootstrap Toolkit <version>"
```

For example:

```bash
git tag -a v3.0.0 -m "Mac Bootstrap Toolkit 3.0.0"
```

Verify the tag:

```bash
git show --no-patch --decorate v<version>
```

Publish it:

```bash
git push origin v<version>
```

The release tag must identify the corresponding stable state on `main`.

---

# 10. Complete Release Verification

Verify the final repository state:

```bash
git status
git log -3 --oneline --decorate
git tag --list
```

Confirm that:

- `main` contains the released version;
- `origin/main` contains the released version;
- tag `v<version>` exists;
- the tag identifies the intended release state;
- `config/toolkit.conf` contains the released version;
- the working tree is clean.

At this point the stable release is published.

---

# 11. Return to `develop`

Switch back to the development branch:

```bash
git checkout develop
```

Synchronize the local branch if necessary:

```bash
git pull --ff-only origin develop
```

Further development continues in `develop`.

A separate `-dev` version bump is not required unless the project explicitly
adopts development-version identifiers in the future.

---

# Release Checklist

Before declaring the release complete, verify:

- [ ] Planned release scope is complete.
- [ ] Required release validation has passed.
- [ ] Release documentation is updated.
- [ ] Release history is consistent.
- [ ] Toolkit version is updated.
- [ ] Release commit is created.
- [ ] `develop` is pushed.
- [ ] `develop` is merged into `main`.
- [ ] Merged `main` is verified.
- [ ] `main` is pushed.
- [ ] Annotated release tag is created.
- [ ] Release tag is pushed.
- [ ] Final release state is verified.
- [ ] Development continues in `develop`.

---

# Branches

```text
develop
```

Primary development branch and preparation point for the next stable release.

```text
main
```

Published stable project history.

Stable release history in `main` must not be rewritten merely to simplify the
Git graph.

---

# Principle

A release does not create a new implementation state.

It publishes and identifies an already completed, documented, and validated
state of the project.

Any maintainer should be able to follow this document from top to bottom and
publish a stable release without relying on additional release instructions.
