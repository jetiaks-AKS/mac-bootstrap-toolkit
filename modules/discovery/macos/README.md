# macOS Discovery

## Назначение

Модуль экспортирует поддерживаемые настройки macOS.

Discovery считывает текущие значения параметров системы и сохраняет их в отдельные конфигурационные файлы.

Настройки никогда не применяются автоматически.

---

## Что анализируется

- Finder — 13 supported settings
- Dock
- Keyboard
- Trackpad
- Screenshots

---

## Результат

После выполнения создаются файлы:

config/generated/macos/

- finder.conf
- dock.conf
- keyboard.conf
- trackpad.conf
- screenshots.conf

Каждая запись использует существующий формат `domain|key|type|value`.
Поддерживаются текущие типы `bool`, `int` и `string`. Float в 9A не добавлен.
Полный текущий allowlist и Screenshot path-контракт описаны в
[Configuration](../../../docs/toolkit/CONFIGURATION.md#macos-generated-records-stage-9a).

Общий validator `modules/settings/macos/records.sh` проверяет candidate-файл
до публикации: category/domain/key/type, дубликаты и безопасное scalar encoding.
Delimiter `|`, ASCII controls (включая NUL) и multiline values запрещены.
Screenshot `location` должен быть непустым absolute path или `~/...`; никакое
shell-выражение не выполняется. Проверка доступности каталога на Target Mac
относится к consumer, а не к source Discovery.

Finder сохраняет семь прежних настроек и шесть новых: `AppleShowAllFiles`,
`NewWindowTarget`, `ShowHardDrivesOnDesktop`, `ShowExternalHardDrivesOnDesktop`,
`ShowMountedServersOnDesktop`, `FXEnableExtensionChangeWarning`.
`NewWindowTarget` ограничен `PfCm/PfVo/PfHm/PfDe/PfDo/PfAF`. Неподдерживаемое
scalar-значение (включая `PfLo`) пропускается с warning и статусом `1` после
успешной публикации остальных валидных записей. `NewWindowTargetPath` не экспортируется.
Ошибки чтения/type и небезопасные scalar-значения сохраняют прежний snapshot с `2`.

---

## Принцип работы

Discovery считывает реальные значения настроек текущего Mac.

Допустимое отсутствие настройки не создаёт запись. Ошибка наблюдения,
сериализации или публикации возвращает ошибку, а не интерпретируется как
отсутствие.

Категории публикуются независимо. Любая обработанная ошибка сбора, проверки, сериализации или публикации сохраняет предыдущий валидный generated-файл соответствующей категории.

Текущий Bootstrap уже использует generated-конфигурацию для применения
поддерживаемых настроек macOS.

Blueprint реализован в `develop` и выбирает категории для Bootstrap.
