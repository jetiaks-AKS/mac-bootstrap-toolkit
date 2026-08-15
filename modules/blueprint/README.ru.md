# Основа Blueprint

[English version](README.md)

Blueprint реализуется поэтапно как слой пользовательского выбора. Сейчас он
предоставляет parser, validation и item-level фильтрацию Bootstrap. Он не
добавляет интерактивный CLI-режим.

Пользовательский файл — `config/blueprint.conf`. Он исключён из Git и никогда
не создаётся автоматически. `config/blueprint.example.conf` содержит
отслеживаемый нейтральный пример.

Формат содержит одну обязательную секцию `[categories]` и шесть обязательных
item-секций:

- `[homebrew-packages]`
- `[homebrew-casks]`
- `[app-store]`
- `[vscode-extensions]`
- `[workspace-folders]`
- `[git-repositories]`

Пустая item-секция выбирает ноль компонентов. Если
`config/blueprint.conf` отсутствует, Bootstrap сохраняет legacy-поведение с
полным scope.

API в `blueprint.sh`:

- `blueprint_exists [file]`
- `blueprint_category_enabled category [file]`
- `blueprint_selected_items section [file]`
- `blueprint_item_selected section item [file]`
- `blueprint_validate [file]`

Validation возвращает `0` для валидного или отсутствующего Blueprint, `1` для
валидного Blueprint с устаревшими выбранными компонентами и `2` для malformed
или неоднозначного ввода. Validation никогда не перезаписывает Blueprint.

Discovery по-прежнему сканирует все поддерживаемые области, а Blueprint хранит
только пользовательский выбор. Generated Configuration остаётся источником
фактических значений. При наличии Blueprint Bootstrap фильтрует Homebrew
packages, Homebrew casks, приложения App Store, расширения VS Code, папки
Workspace и Git-репозитории по соответствующим item-секциям.

Фильтрация категорий и модулей пока не реализована: Git Configuration, VS Code
Settings и настройки macOS не управляются секцией `[categories]`. Интерактивной
команды `--blueprint` и Dry-run пока нет.
