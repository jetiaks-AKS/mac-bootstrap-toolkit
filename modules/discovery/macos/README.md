# macOS Discovery

## Назначение

Модуль экспортирует поддерживаемые настройки macOS.

Discovery считывает текущие значения параметров системы и сохраняет их в отдельные конфигурационные файлы.

Настройки никогда не применяются автоматически.

---

## Что анализируется

- Finder — 13 supported settings
- Dock — 9 supported settings
- Keyboard — 9 supported settings
- Trackpad — 2 supported stored preferences
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

Dock сохраняет пять прежних настроек и шесть новых: `orientation`, `mineffect`,
`minimize-to-application`, `show-process-indicators`, `launchanim`, `mru-spaces`. Для `orientation` допустимы
`left/bottom/right`, для `mineffect` — `genie/scale`. Неподдерживаемый scalar enum
пропускается с warning и статусом `1` после публикации остальных валидных records.
Absent preferences не получают синтезированных defaults; observation/type/scalar
ошибки сохраняют прежний Dock snapshot с `2`.

Window Management сохраняет четыре `NSGlobalDomain` preference в отдельный
`windows.conf`: `AppleActionOnDoubleClick`, `AppleWindowTabbingMode`,
`NSCloseAlwaysConfirmsChanges`, `NSQuitAlwaysKeepsWindows`. Первый enum допускает
`Minimize/Maximize/Fill/None`, второй — `manual/always/fullscreen`. Unsupported
enum пропускается с warning; absent остаётся unmanaged. Категория не требует
process restart и проверяет сохранённое preference read-back, а не видимый эффект
в уже открытых приложениях.

Keyboard сохраняет `KeyRepeat`, `InitialKeyRepeat` и семь новых настроек:
`ApplePressAndHoldEnabled`, `AppleKeyboardUIMode`, `NSAutomaticCapitalizationEnabled`,
`NSAutomaticSpellingCorrectionEnabled`, `NSAutomaticPeriodSubstitutionEnabled`,
`NSAutomaticQuoteSubstitutionEnabled`, `NSAutomaticDashSubstitutionEnabled`.
`AppleKeyboardUIMode` — int без нового диапазона; остальные новые ключи — bool.
Absent values остаются unmanaged. Ошибка сбора/валидации сохраняет предыдущий
Keyboard snapshot. Bootstrap выбирает все managed records через `macos-keyboard`
и не перезапускает процессы.

Trackpad сохраняет ровно два bool records из `com.apple.AppleMultitouchTrackpad`:
`Clicking` и `TrackpadRightClick`. Они описывают primary stored preferences, без
обещания синхронизации external Magic Trackpad, Bluetooth или ByHost state.
Tracking speed исключён из supported inventory; старый generated record с
`com.apple.trackpad.scaling` не проходит validation и требует повторной Discovery.
Natural Scrolling, дополнительные gestures и hardware-aware restoration deferred.

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
