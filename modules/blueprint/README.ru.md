# Blueprint MVP

[English version](README.md)

Blueprint — слой пользовательского выбора между Discovery и Bootstrap. Он
предоставляет parser, validation, item-level и category/module-level фильтрацию
Bootstrap, а также интерактивный selector `--blueprint`. Stages 1–5 завершены и
прошли полную E2E-проверку в `develop`; в стабильный релиз 2.0.1 они ещё не входят.

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

Workspace Discovery сохраняет в `folders.conf` наблюдаемые записи `system`,
`user` и `workspace`. Blueprint предлагает как обычные Workspace Folder
кандидаты только записи с точной классификацией `workspace`. При сохранении
существующего Blueprint legacy-выбор `user` и `system` удаляется; отмена
сохраняет исходный файл. Без Blueprint Bootstrap сохраняет широкое
legacy-поведение.

Секция `[categories]` независимо управляет Git Configuration, VS Code Settings
и модулями macOS Finder, Dock, Keyboard, Trackpad и Screenshots. Расширения
VS Code по-прежнему управляются отдельно своей item-секцией.

Создать или изменить локальный Blueprint можно командами:

```text
./bootstrap.sh --discover
./bootstrap.sh --blueprint
./bootstrap.sh --bootstrap
```

Для каждой области обнаруженных компонентов selector предлагает All, None или
Edit. Режим Edit показывает текущее состояние checkbox на страницах по 10
компонентов. Введённые номера переключают checkbox; их можно разделять запятыми
или пробелами, а также вводить диапазоны `5-9` и смешанные выражения
`1,3,7-10`. Повторный запуск `--blueprint` загружает текущий выбор для
редактирования.

Selector записывает файл только после подтверждения. Отмена не изменяет
существующий Blueprint и не создаёт новый.

Blueprint остаётся локальным, приватным и исключённым из Git. Dry-run пока не
реализован.

При активном Blueprint итоговый Bootstrap Summary показывает selected/total
counts для компонентов и Enabled/Skipped для категорий настроек. Детальный
вывод компонентов остаётся в `--verbose`.
