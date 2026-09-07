# CLI, Output and Logging

## Назначение

Этот документ определяет единый контракт пользовательского CLI-вывода и
диагностического логирования Mac Bootstrap Toolkit.

Обе части используют общий Logger, но имеют разные задачи:

- **CLI Output** показывает пользователю текущее действие и итог выполнения;
- **History Logging** сохраняет диагностическую историю запуска.

Бизнес-логика Toolkit не должна зависеть от способа отображения или сохранения
сообщений.

---

# Основные принципы

- Quiet by Default;
- Verbose When Needed;
- единый формат сообщений;
- понятные секции и статусы;
- обязательный итоговый Summary;
- диагностические подробности сохраняются в history log;
- один результат не должен многократно сообщаться пользователю;
- Logger представляет и сохраняет информацию, но не принимает domain-решения.

---

# Типы сообщений

```text
[....] Action
[ OK ] Success
[WARN] Warning
[ERROR] Error
[INFO] Information
```

## Action

Показывает выполняемое действие.

```text
[....] Installing Homebrew packages...
```

## Success

Показывает успешное завершение операции.

```text
[ OK ] Homebrew already installed
```

## Warning

Показывает ситуацию, которая требует внимания, но не обязательно останавливает
работу Toolkit.

```text
[WARN] Configuration file not found
```

## Error

Показывает ошибку, из-за которой операция не может быть нормально завершена.
Сообщение должно по возможности объяснять причину проблемы.

```text
[ERROR] Bootstrap failed
```

## Info и Detail

`info()` показывает информационное сообщение пользователю и записывает его в
лог.

Для диагностических подробностей, которые должны появляться на экране только с
`--verbose`, используется `detail()`.

History log сохраняет диагностическую информацию независимо от того, была ли
каждая подробность показана в стандартном CLI-выводе.

---

# Режимы CLI-вывода

## Standard / Quiet

Стандартный режим показывает только информацию, необходимую для понимания
выполнения:

- основные действия;
- успешные результаты;
- предупреждения;
- ошибки;
- итоговый Summary.

Пример:

```text
==========================================
 Homebrew Packages
==========================================
[ OK ] All Homebrew packages are installed.
```

Интерактивный Blueprint selector является отдельным workflow: selection state и
prompts необходимы пользователю для принятия решений, поэтому его интерфейс не
обязан быть таким же кратким, как неинтерактивный вывод.

## Verbose

`--verbose` дополняет обычный вывод диагностическими подробностями, контекстом
ошибок и внутренними этапами выполнения там, где это полезно.

Verbose не меняет семантику выполнения Toolkit. Blueprint selector может иметь
мало видимых отличий в verbose-режиме, поскольку уже показывает необходимую
пользователю информацию.

---

# Секции

Основные компоненты Toolkit по возможности используют единый формат секций:

```text
==========================================
 Homebrew
==========================================
[ OK ] Homebrew already installed
```

Секция помогает быстро определить текущий или уже обработанный компонент.

---

# Результаты выполнения

Toolkit различает следующие состояния:

- **Success** — операция успешно завершена;
- **Changed / Installed** — существующий lifecycle фактически изменил состояние;
- **Unchanged / Skipped** — изменение не требовалось;
- **Warning** — работа продолжена, но требуется внимание;
- **Error** — операция не была успешно завершена.

Preview выводит planned actions через `Would ...`; отдельный статус
`Planned` не используется. Сами planned actions возвращают `0`.

---

# Summary

Summary зависит от режима и контекста запуска и не должен дублировать детальный
lifecycle из history log.

## Lifecycle/count Summary

Check и Bootstrap без Blueprint используют существующий Summary
жизненного цикла. Он может включать:

```text
Modules Checked
Installed
Skipped
Warnings
Errors
Duration
```

Пример:

```text
==========================================
 Summary
==========================================
[ OK ] Bootstrap completed successfully

------------------------------------------
Modules Checked : 11
Installed       : 0
Skipped         : 11
Warnings        : 0
Errors          : 0
------------------------------------------
Duration        : 15s
```

Discovery использует отдельный набор полей:

```text
Modules Processed : 10
Warnings          : 0
Errors            : 0
```

`Modules Processed` — существующий счётчик вызовов `run_module()`, включая
четыре общих Core-модуля и шесть Discovery-модулей при полном проходе.
Это не число обнаруженных компонентов или опубликованных файлов. `Warnings`
и `Errors` сохраняют существующий учёт результатов lifecycle, включая ошибку
preflight; они не считают каждое отдельное сообщение. При остановке на
preflight число обработанных модулей равно нулю. Поля `Installed` и `Skipped`
в Discovery Summary не выводятся. `Duration` сохраняется при наличии времени
начала запуска. Терминал и лог содержат одинаковые поля и значения.

Во всех режимах headline определяется lifecycle-счётчиками с приоритетом:

```text
ERROR_COUNT > 0
→ <Mode> completed with errors

иначе WARNING_COUNT > 0
→ <Mode> completed with warnings

иначе
→ <Mode> completed successfully
```

Ошибки имеют приоритет над предупреждениями. Success-only выполнение сохраняет
exit status `0`, warning-only — `1`, выполнение с ошибкой — `2`. Отрисовка
Summary не меняет счётчики или итоговый lifecycle status.

## Blueprint selector Summary

Интерактивный selector перед Save показывает selection Summary: selected / total
для item-категорий и Yes / No для категорий настроек. Это подтверждение выбора,
а не Summary выполнения Bootstrap.

## Blueprint-aware Bootstrap Summary

Bootstrap с Blueprint показывает выбранный scope и результат выполнения.
Например:

```text
Applications
  Homebrew packages      28 / 28 selected
  Homebrew casks          3 / 16 selected

Workspace
  Folders                 2 / 4 selected

Settings
  Git Configuration      Enabled
  VS Code Settings       Skipped

Result
  Warnings               0
  Errors                 0

Duration                 15s
```

`Enabled` означает «выбрано в Blueprint», а не «изменено в текущем запуске».

---

# History Logging

Каждый запуск Toolkit сохраняет историю в:

```text
logs/
    latest.log
    history/
```

`logs/latest.log` содержит последний запуск, а `logs/history/` — отдельные
исторические логи.

Имена history-файлов соответствуют режиму:

```text
check-YYYY-MM-DD_HH-MM-SS.log
bootstrap-YYYY-MM-DD_HH-MM-SS.log
discover-YYYY-MM-DD_HH-MM-SS.log
blueprint-YYYY-MM-DD_HH-MM-SS.log
```

Логи являются локальными рабочими файлами Toolkit и не должны попадать в Git.

Каждая запись содержит timestamp, например:

```text
2026-08-10 19:16:45 [ OK ] Bootstrap completed successfully
```

---

# Module Lifecycle в логах

Основные модули могут фиксировать диагностический lifecycle:

```text
[MODULE] START: Homebrew
[MODULE] Changed: No
[MODULE] RESULT: SUCCESS
```

При изменении:

```text
[MODULE] Changed: Yes
```

Другие результаты:

```text
[MODULE] RESULT: WARNING
[MODULE] RESULT: ERROR
[MODULE] RESULT: UNKNOWN
```

`UNKNOWN` используется для неожиданного кода завершения.

Эти записи предназначены прежде всего для диагностики и не должны перегружать
стандартный CLI-вывод.

## Blueprint Lifecycle

Blueprint использует минимальный lifecycle:

```text
[BLUEPRINT] START
[BLUEPRINT] Generated configuration: Ready
[BLUEPRINT] Existing configuration: Valid
[BLUEPRINT] RESULT: SAVED
```

При отмене:

```text
[BLUEPRINT] RESULT: CANCELLED
```

`Existing configuration: Valid` записывается только после успешной валидации.
При stale или malformed Blueprint сохраняются существующие warning/error
семантики без ложной записи `Valid`.

Выбранные элементы, checkbox-операции, ответы по категориям и содержимое
`config/blueprint.conf` намеренно не копируются в lifecycle log. Источником
состояния выбора остаётся сам Blueprint.

---

# Прерывание Toolkit

Logging System обрабатывает `INT` и `TERM`.

При прерывании в лог записывается:

```text
[WARN] Toolkit interrupted
Finished : YYYY-MM-DD HH:MM:SS
Duration : Ns
Status   : Interrupted
```

После этого текущий лог сохраняется как `latest.log`. Это позволяет отличать
успешное, ошибочное и прерванное завершение и сохранять диагностический контекст.

---

# Dry-run / Preview

`--dry-run` является отдельным execution mode. Одновременно можно выбрать
ровно один из `--check`, `--bootstrap`, `--discover`, `--blueprint` и
`--dry-run`; отсутствие mode или конфликтующие mode-флаги возвращают `1`.

Preview выполняет последовательность:

```text
CLI parse → Logger → Blueprint validation → selected input validation
→ read-only preflight → read-only Core inspection
→ domain Preview → Summary → exit code
```

Он не вызывает `sudo -v`, не устанавливает Homebrew и не запускает Bootstrap
mutations. Applications, Git configuration, VS Code settings, Workspace и macOS
Preview используют
существующие validators, Blueprint selection и inspection helpers и могут
вывести:

```text
Would install Homebrew formula: <name>
Would install Homebrew cask: <name>
Would reinstall Homebrew cask: <name>
Would install App Store app: <name> (<id>)
Would install VS Code extension: <id>
Would configure Git setting: <key>
Would update VS Code settings
Would create workspace folder: <path>
Would clone repository: <id>
Would switch repository branch: <id> -> <branch>
Would change macOS setting: <domain/key> (<current> -> <desired>)
Would change macOS setting: <domain/key> (absent -> <desired>)
Would create screenshots directory: <path>
Would restart process: <process>
```

Уже соответствующие состоянию и невыбранные элементы не выводятся как planned
actions. Сами planned actions сохраняют status `0`; observation error возвращает
`2`. Summary Preview показывает `Modules Inspected`, `Warnings` и `Errors`, без
Bootstrap-полей `Installed` и `Skipped`. Stale Blueprint сохраняет warning
status; malformed Blueprint или обязательный selected input возвращает `2`.
Отсутствующий optional source VS Code settings сохраняет warning status.
Workspace Preview сохраняет текущую warning-политику для dirty repositories,
remote mismatch и существующих non-Git destinations. После clone-плана он не
предполагает будущую branch state. macOS Preview использует typed defaults
inspection; один restart-план выводится для изменяемой Finder, Dock или
Screenshots category независимо от количества изменяемых settings.

Порядок domain inspections: Homebrew formulae → casks → App Store → VS Code
extensions → Git configuration → VS Code settings → Workspace folders →
repositories → macOS. Disabled selections сохраняют существующую фильтрацию.

Ошибки startup validation и preflight останавливают запуск. После ошибки Core
или domain inspection последующие read-only inspections продолжаются;
ошибка сохраняется в общем accounting и итоговый exit code равен `2`.
Внутри domain helper ошибка может остановить оставшиеся items этого helper.
Warnings без errors дают `1`; planned actions без warnings/errors дают `0`.
`Modules Inspected` считает вызовы inspection wrapper, включая Core и Blueprint
validation при его наличии; это не число items. Terminal и logger используют
одинаковые Summary counters, без `MODULE_CHANGED`, Installed или Skipped.

---

# Архитектурное правило

```text
Module
   ↓
Result
   ├── CLI Presentation
   └── History Logging
```

CLI объясняет пользователю, что происходит и чем завершилась операция.
Logging сохраняет необходимый диагностический контекст и историю.

Logger не содержит бизнес-логику. Решения о состоянии системы, конфигурации и
необходимых действиях принимают соответствующие модули.

Реализованные режимы:

```text
Check
Discovery
Blueprint
Bootstrap
Preview (`--dry-run`)
```

Global Verification остаётся запланированной возможностью.
