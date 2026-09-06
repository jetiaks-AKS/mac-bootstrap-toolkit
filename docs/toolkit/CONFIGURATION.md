# Конфигурация Mac Bootstrap Toolkit

## Назначение

Конфигурационная модель Toolkit отделяет обнаруженные данные рабочего
окружения, пользовательский выбор и логику применения:

```text
Discovery
    ↓
Generated Configuration
    +
Blueprint Desired Selection
    ↓
Selected Supported State
    ↓
Bootstrap
```

Discovery наблюдает поддерживаемое текущее состояние. Generated Configuration
хранит machine-specific обнаруженные значения. Blueprint хранит Desired
Selection — категории и компоненты, включённые в scope восстановления.
Bootstrap объединяет generated-значения с этим выбором и применяет выбранное
поддерживаемое состояние.

## Модель состояния

- **Observed State** — поддерживаемое состояние, обнаруженное на исходном Mac.
- **Generated Configuration** — локальное представление обнаруженных значений.
- **Blueprint Desired Selection** — выбор категорий и компонентов из
  обнаруженного inventory.
- **Selected Supported State** — generated-значения, входящие в выбранный
  scope и доступные текущим Bootstrap consumers.

Blueprint не владеет обнаруженными значениями, не копирует и не перезаписывает
их. Observed State и Desired Selection остаются разными ответственностями.

## Generated Configuration

`config/generated/` — локальное приватное machine-specific производное
состояние, создаваемое Discovery. Каталог исключён из Git и может содержать
личные пути, Git identity, repository URLs и настройки приложений.

Generated Configuration является источником обнаруженного inventory для Blueprint и источником применяемых значений для Bootstrap. Форматы producers и consumers должны оставаться совместимыми, а пользовательские значения не должны без необходимости дублироваться в
Bootstrap-коде.

### Безопасная публикация

Обычный lifecycle экспортёра:

```text
Collect → Validate → Serialize → Safe Publication
```

Generated-файл заменяется только после успешного сбора, валидации и
сериализации нового результата. Обработанная ошибка сбора, сериализации или
публикации сохраняет предыдущий валидный generated-файл.

Большинство generated-файлов публикуются независимо. Workspace metadata в
`workspace.conf` также публикуется отдельно. Четыре производных файла:

- `folders.conf`;
- `repositories.conf`;
- `vscode-workspaces.conf`;
- `inventory.conf`

образуют один grouped Workspace snapshot и публикуются совместно.

## Blueprint

Локальный приватный `config/blueprint.conf` хранит только Desired Selection и
исключён из Git. Нейтральная структура формата приведена в
[blueprint.example.conf](../../config/blueprint.example.conf).

Blueprint поддерживает:

- item-level selection для обнаруженных компонентов;
- category/module-level selection для поддерживаемых consumers;
- применение выбранного scope с использованием значений из Generated
  Configuration.

Для `[workspace-folders]` обычными Blueprint-кандидатами являются записи
`folders.conf` с классификацией `workspace`. Наблюдаемые каталоги `user` и
`system` остаются в Generated Configuration, но не предлагаются как обычные
Workspace Folder choices.

При отсутствии Blueprint Bootstrap сохраняет совместимое legacy
all-inclusive-поведение для поддерживаемого generated scope. Interactive
Blueprint selector доступен для создания и изменения локального выбора; его UX
описывается в документации Blueprint.

## Контракты конфигурации

Toolkit намеренно не требует одного универсального формата. Формат является
контрактом конкретных producer и consumer и выбирается под представляемые
данные.

Текущие основные форматы:

- простые списки для application inventories;
- native Git configuration для глобального Git-состояния;
- структурированные Workspace configurations;
- typed macOS records в формате `domain|key|type|value`.

Конфигурация должна разбираться как данные. Способ чтения обязан соответствовать
формату и не превращать generated-содержимое в выполняемый shell-код.

### Homebrew formula generated state

`config/generated/brew-packages.conf` сохраняет формат одного имени на строку.
Пустые строки и комментарии с `#` в начале строки игнорируются. Допускаются
имена formulae и `owner/tap/formula`: каждый компонент начинается с ASCII-буквы
или цифры и далее содержит только буквы, цифры, `+`, `_`, `.`, `@`, `-`.
Пробелы, option-like значения, пути, URL и ссылки на `.rb`-файлы отвергаются.
Последняя строка без завершающего перевода строки поддерживается.

Consumer читает и валидирует весь список до первого install, включая записи
вне выбранного subset. Отсутствующий, нечитаемый или malformed файл возвращает
`2` без установок. Пустой Blueprint scope сохраняет ранний выход без чтения
этого input и без обращения к Homebrew.

Присутствие определяется по успешно прочитанному `brew list --formula --full-name`.
Короткие имена Discovery сопоставляются с именем formula, полные — с точным tap.
Неоднозначное короткое имя или ошибка inventory возвращают `2`, а не означают
отсутствие. После успешного install consumer повторно проверяет присутствие.
Ошибка install или Verify возвращает `2`; сообщение об успешной установке
появляется только после Verify.

Bootstrap не транзакционный: успешная install-команда устанавливает
`MODULE_CHANGED=true`; последующая ошибка другой установки или Verify не
сбрасывает этот признак и не откатывает ранее выполненные установки.

### Git generated state

`config/generated/git.conf` использует native non-executable Git config format
и содержит только поддерживаемые ключи:

- `user.name`;
- `user.email`;
- `init.defaultBranch`;
- `pull.rebase`;
- `core.editor`.

Отсутствующий ключ означает, что он не был глобально настроен на наблюдаемом
Mac. Consumers читают файл через `git config --file ... --no-includes`; его
содержимое никогда не должно выполняться через `source` или `eval`.

## Конфигурация и модули

Конфигурация содержит данные, а модули определяют поведение для этих данных.
Например, обнаруженный размер Dock должен поступать в Bootstrap из Generated
Configuration, а не дублироваться как фиксированное значение в коде.

Обязательный generated-ввод валидируется до мутации там, где он требуется.
Отсутствующее, нечитаемое или malformed обязательное состояние не должно
использоваться для частичного применения.

## Будущие потребители

Dry-run / Preview и Global Verification запланированы и пока не реализованы.

- **Dry-run / Preview** будет неизменяющим режимом Bootstrap и станет
  использовать те же Generated Configuration и Blueprint Desired Selection.
  Он не является источником конфигурации и не владеет Desired Selection.
- **Global Verification** станет aggregate post-Bootstrap проверкой выбранного
  итогового состояния. Она отличается от текущего локального
  `Check → Apply → Verify`, уже используемого модулями там, где проверка
  результата поддерживается.

## Основные принципы

1. Обнаруженные значения и Desired Selection остаются разными
   ответственностями.
2. Generated Configuration остаётся локальным производным состоянием.
3. Blueprint хранит выбор, а не копию generated-значений.
4. Producer и consumer сохраняют совместимость формата.
5. Предыдущее состояние заменяется только после подготовки нового валидного
   результата.
6. Конфигурация содержит данные; модули содержат поведение.

Архитектурные границы подробнее описаны в
[ARCHITECTURE.ru.md](ARCHITECTURE.ru.md), а этапы реализации — в
[ROADMAP.md](../../ROADMAP.md).
