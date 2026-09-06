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

### Остальные application generated inputs

Homebrew casks, App Store и VS Code extensions читаются отдельными
consumer-specific helpers. Каждый helper проверяет наличие и читаемость файла
и формирует полностью валидированный снимок записей в памяти. Consumers начинают
наблюдение и Apply только после успешного чтения всего снимка; поздняя ошибка
не допускает установки предыдущих валидных записей.

Для всех трёх списков сохраняются пустые строки, комментарии с `#` в начале
строки и последняя запись без newline. Ошибка обязательного input возвращает
`2` без мутаций и без изменения `MODULE_CHANGED` со стороны validator.

- **Casks — `brew-casks.conf`:** один короткий cask token на строку, начиная
  с ASCII-буквы или цифры; далее допустимы буквы, цифры, `+`, `_`, `.`, `@`, `-`.
  Пробелы, slash-пути, URL, option-like значения и окончания
  `.rb`, `.json`, `.sh`, `.bash`, `.zsh`, `.dmg`, `.pkg`, `.zip` отвергаются.
  Tap-qualified syntax не добавляется: текущий Discovery экспортирует токены.
- **App Store — `appstore.conf`:** ровно два поля `ID|name`. ID содержит только
  ASCII-цифры; имя непустое, не начинается с `-`, не содержит крайних пробелов,
  управляющих символов или дополнительного `|`. Внутренние пробелы, Unicode и обычная пунктуация
  сохраняются. Наличие приложения определяется только по точному ID из `mas list`;
  имя используется для сообщений.
- **VS Code — `vscode-extensions.conf`:** ровно `publisher.extension`.
  Каждая часть начинается с ASCII-буквы или цифры и далее содержит только
  буквы, цифры, `_`, `-`. Пути, URL, option-like значения, version suffixes
  и локальные `.vsix`-ссылки не поддерживаются.

Пустой Blueprint scope сохраняет ранний успешный выход без чтения input и CLI.
При непустом scope валидируется весь требуемый файл до фильтрации отдельных
записей существующим Blueprint API; файлы других consumers не проверяются.
Невалидный input имеет приоритет над отсутствием CLI. При валидном input
отсутствующий `mas` или `code` по-прежнему возвращает warning `1`, Homebrew — `2`.

App Store и VS Code extensions используют локальный `Check → Apply → Verify`:
перед установкой выбранного элемента читается текущий inventory; ошибка чтения
возвращает `2` и не считается отсутствием. После успешной install-команды
устанавливается `MODULE_CHANGED=true`, затем inventory читается повторно.
Verify требует точного App Store ID или полного case-sensitive extension ID,
без нормализации регистра. Success выводится только после Verify.
Ошибка install, повторного чтения или отсутствие элемента после установки
возвращает `2`. Ранее успешные мутации сохраняют `MODULE_CHANGED=true`;
отката нет. Это локальный Verify, а не будущая Global Verification.

Homebrew casks используют тот же локальный lifecycle. Check требует точного
токена в `brew list --cask` и наличия всех top-level `target` из
`brew info --json=v2 --cask`: это разрешённые Homebrew пути relocated artifacts,
а не только первый app target. Отсутствующий токен требует install; отсутствующий
целевой путь установленного cask требует reinstall. Artifacts без `target`
(например, pkg, uninstall, zap) не получают дополнительных проверок.
Нечитаемый inventory, невалидная структура metadata или target (не абсолютная
строка либо содержит управляющие символы) возвращают `2` без Apply.
После успешного install/reinstall сразу устанавливается `MODULE_CHANGED=true`,
затем повторяется тот же Check. Success возможен только после Verify;
его ошибка или ошибка следующего cask не сбрасывает уже установленный Changed.

### Workspace Bootstrap actionability

Bootstrap сохраняет текущие форматы: `folder|classification` для `folders.conf`
и секции с `NAME`, `PATH`, `REMOTE`, `CURRENT_BRANCH` и Discovery metadata для
`repositories.conf`. `CURRENT_BRANCH`, а не новый `BRANCH`, задаёт ветку Apply.
`workspace.conf` описывает обнаруженный HOME; он не переназначает целевой root
Bootstrap, которым остаётся текущий `$HOME`.

Перед мутациями Workspace проверяет оба требуемых inputs. Каждый consumer также
собирает полный валидированный selected snapshot перед своим Apply. Для чтения
секций/значений используется Configuration Engine; section IDs с пробелами
читаются построчно. Последняя запись без newline поддерживается, пустые строки
пропускаются. Новый синтаксис комментариев или escaping не добавляется.

Selected folders допускают простые и вложенные относительные пути с пробелами.
Absolute paths, пустые компоненты, `.`/`..`, управляющие символы и существующие
symlink-компоненты, ведущие вне HOME, отвергаются. Repository `PATH` должен быть
абсолютным потомком текущего HOME и удовлетворять тем же правилам. Существующие
компоненты пути должны быть каталогами.

Структура repository-файла проверяется существующим snapshot validator.
Selected `NAME`, `REMOTE`, `CURRENT_BRANCH` не могут быть пустыми; управляющие
символы и неоднозначные кавычки в action fields отвергаются. Section IDs с
backslash не поддерживаются существующим Configuration Engine и отклоняются.
REMOTE сохраняет SSH/scp, URL и local-path формы; пустые/option-like значения,
крайние пробелы и пустые части URL/scp отвергаются без сетевых запросов.
CURRENT_BRANCH проверяется локальным `git check-ref-format --branch`; option-like
значения и сокращения, требующие расширения Git, не допускаются.

Ошибка обязательного input возвращает `2` до mkdir/clone/checkout, включая
ошибку поздней записи. Пустой Blueprint scope не требует соответствующего файла;
структура требуемого файла проверяется целиком, actionability — для selected
элементов через существующий Blueprint API. Discovery validators, generated
форматы и clone/checkout lifecycle этим изменением не расширяются.

Selected Workspace folders используют локальный `Inspect → Apply → Verify`
после полной W1 validation. Inspection возвращает `0` только для доступного
каталога в пределах HOME, `1` для подтверждённого отсутствия и `2` для wrong-type,
небезопасного symlink или ошибки доступа. Только состояние `1` разрешает
`mkdir -p`. После успешной команды устанавливается `MODULE_CHANGED=true`, затем
тот же inspector должен подтвердить каталог; success выводится после Verify.
Ошибка mkdir без созданного каталога не устанавливает Changed. Если mkdir успел
создать часть вложенного пути до ошибки, это retained изменение учитывается.
Поздняя ошибка не сбрасывает ранее установленный Changed; rollback отсутствует.
Повторный запуск для подтверждённого каталога не выполняет mutation.

Workspace orchestration прекращает работу с `2` сразу после folder lifecycle
error и не запускает repository Apply. Warning `1` сохраняет существующую
агрегацию. Это локальный module Verify, а не будущая Global Verification.

### Workspace repository inspection

Repository inspection использует явные статусы: `0` — подтверждённое состояние,
`1` — отсутствие/несоответствие, `2` — ошибка наблюдения. Перед clone проверяется
доступность существующего предка destination. Существующий каталог без `.git`
остаётся warning `1`; `.git` directory или worktree-file проверяется локальным
`git rev-parse --is-inside-work-tree`. Ошибка Git или доступа возвращает `2`.

Origin mismatch остаётся warning `1`; ошибка чтения origin (включая отсутствующий
origin) возвращает `2`. Успешный `branch --show-current` с пустым выводом означает
текущий detached HEAD: сохраняется прежняя возможность восстановить выбранную
ветку после подтверждения clean state. Ошибка чтения ветки не считается mismatch.

Clean-state по-прежнему учитывает только tracked/staged изменения: оба `git diff
--quiet` проверяются отдельно. `0` — оба clean, `1` — есть изменения, `2` — хотя бы
одна ошибка чтения, даже если другая проверка обнаружила dirty state. Untracked
файлы не становятся новым критерием dirty. Inspection error блокирует действие
для этого repository и немедленно возвращает module error `2`.

Clone выполняется только после подтверждённого отсутствия destination. После
успешной команды устанавливается `MODULE_CHANGED=true`, затем повторно
проверяются наличие destination, usable Git worktree и точный origin. Любая
ошибка или несовпадение Verify возвращает `2`; success о clone выводится только
после этих проверок.

Checkout выполняется только для подтверждённого branch mismatch или detached
HEAD после clean-state `0`. После успешной команды устанавливается
`MODULE_CHANGED=true`, затем branch читается повторно и должен точно совпадать с
`CURRENT_BRANCH`. Ошибка чтения или mismatch возвращает `2`; сообщение о
восстановлении ветки выводится после Verify. Ошибка mutating-команды также
возвращает `2`. Ранее успешное изменение сохраняет Changed при поздней ошибке;
rollback не выполняется.

### VS Code settings lifecycle

`config/generated/vscode/settings.json` остаётся optional byte-for-byte snapshot:
отсутствующий файл возвращает warning `1`; существующий источник должен быть
читаемым обычным файлом, иначе `2`. Содержимое (включая комментарии JSONC)
не преобразуется и не проверяется новым JSON-парсером.

До Apply источник полностью читается, а `cmp` различает равенство (`0`),
отсутствие/различие (`1`) и ошибку наблюдения (`2`). При равенстве нет mkdir,
backup или copy. При различии создаётся недостающий destination directory,
существующий settings сохраняется в `settings.json.bootstrap.bak`, затем
публикуется новый settings. Копии сначала пишутся во временный файл рядом
с destination и публикуются через rename; неудачный copy не оставляет
усечённый settings или backup. Временные файлы удаляются при обработанной ошибке.
Отличающийся settings-symlink и backup-symlink не заменяются: Apply возвращает
`2`; уже равный settings-symlink сохраняет успешный no-op.

Созданные каталоги (включая частичный mkdir), опубликованный backup и settings
считаются target-visible изменениями и устанавливают `MODULE_CHANGED=true`.
Неудачная staging-копия сама по себе не устанавливает Changed. Успешный backup
с последующей ошибкой settings-copy сохраняет Changed; старый settings остаётся
целым. После публикации тот же comparison должен подтвердить полное равенство;
ошибка или несовпадение возвращают `2`, без success и без сброса Changed.
Blueprint category gate остаётся в Bootstrap orchestration.

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
