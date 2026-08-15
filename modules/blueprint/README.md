# Blueprint foundation

[Русская версия](README.ru.md)

Blueprint Stage 1 provides parsing and validation for the future user-selection
layer. It does not change Discovery or Bootstrap behavior and does not add an
interactive CLI mode.

The user-specific file is `config/blueprint.conf`. It is ignored by Git and is
never generated automatically. `config/blueprint.example.conf` contains the
tracked neutral example.

The format contains one required `[categories]` section and six required item
sections:

- `[homebrew-packages]`
- `[homebrew-casks]`
- `[app-store]`
- `[vscode-extensions]`
- `[workspace-folders]`
- `[git-repositories]`

An empty item section selects zero items. When `config/blueprint.conf` is
absent, the selection API reports legacy all-inclusive behavior for future
Bootstrap integration.

The Stage 1 API in `blueprint.sh` is:

- `blueprint_exists [file]`
- `blueprint_category_enabled category [file]`
- `blueprint_selected_items section [file]`
- `blueprint_item_selected section item [file]`
- `blueprint_validate [file]`

Validation returns `0` for a valid or absent Blueprint, `1` for a valid
Blueprint with stale selected items, and `2` for malformed or ambiguous input.
Validation never rewrites the Blueprint.

Discovery still scans every supported area, while Blueprint stores only the
user's selection. Bootstrap is not yet filtered through Blueprint at the
current implementation stage; there is no interactive `--blueprint` command or
Dry-run yet.
