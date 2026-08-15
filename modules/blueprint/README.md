# Blueprint foundation

[Русская версия](README.ru.md)

Blueprint is being implemented incrementally as the user-selection layer.
It currently provides parsing, validation, item-level Bootstrap filtering, and
category/module-level Bootstrap filtering. It does not add an interactive CLI
mode.

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
absent, Bootstrap retains its legacy all-inclusive behavior.

The API in `blueprint.sh` is:

- `blueprint_exists [file]`
- `blueprint_category_enabled category [file]`
- `blueprint_selected_items section [file]`
- `blueprint_item_selected section item [file]`
- `blueprint_validate [file]`

Validation returns `0` for a valid or absent Blueprint, `1` for a valid
Blueprint with stale selected items, and `2` for malformed or ambiguous input.
Validation never rewrites the Blueprint.

Discovery still scans every supported area, while Blueprint stores only the
user's selection. Generated Configuration remains the source of actual values.
When a Blueprint exists, Bootstrap filters Homebrew packages, Homebrew casks,
App Store applications, VS Code extensions, workspace folders, and Git
repositories by their corresponding item sections.

The `[categories]` section independently controls Git Configuration, VS Code
Settings, and the Finder, Dock, Keyboard, Trackpad, and Screenshots macOS
modules. VS Code extensions remain controlled separately by their item section.

Blueprint is not yet a fully completed user-facing feature. There is no
interactive `--blueprint` command or Dry-run yet.
