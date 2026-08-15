# Основа Blueprint

[English version](README.md)

Blueprint Stage 1 предоставляет parser и validation для будущего слоя
пользовательского выбора. Он не меняет поведение Discovery или Bootstrap и не
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
`config/blueprint.conf` отсутствует, selection API сообщает о legacy-режиме с
полным scope для будущей интеграции с Bootstrap.

API Stage 1 в `blueprint.sh`:

- `blueprint_exists [file]`
- `blueprint_category_enabled category [file]`
- `blueprint_selected_items section [file]`
- `blueprint_item_selected section item [file]`
- `blueprint_validate [file]`

Validation возвращает `0` для валидного или отсутствующего Blueprint, `1` для
валидного Blueprint с устаревшими выбранными компонентами и `2` для malformed
или неоднозначного ввода. Validation никогда не перезаписывает Blueprint.

Discovery по-прежнему сканирует все поддерживаемые области, а Blueprint хранит
только пользовательский выбор. На текущем этапе Bootstrap ещё не фильтруется
через Blueprint; интерактивной команды `--blueprint` и Dry-run пока нет.
