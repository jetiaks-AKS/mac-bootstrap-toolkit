# Output System

## Назначение

Output System определяет, как Mac Bootstrap Toolkit
представляет информацию пользователю.

Основная цель — сделать вывод:

- понятным;
- компактным;
- предсказуемым;
- информативным;
- удобным для диагностики.

Output System работает совместно с Logging System.

Output System отвечает за пользовательское представление
результата, а Logging System дополнительно сохраняет
детальную информацию о выполнении и истории запусков.

---

# Режимы вывода

## Quiet Mode

Quiet Mode является стандартным режимом работы.

Он показывает только информацию, необходимую для понимания
результата выполнения:

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

Quiet Mode не должен перегружать пользователя техническими
подробностями.

Blueprint selector является намеренно интерактивным workflow: он показывает
selection state и prompts, необходимые для решений пользователя. Поэтому его
интерактивный интерфейс не обязан быть таким же кратким, как вывод
неинтерактивных режимов.

---

## Verbose Mode

Verbose Mode предназначен для диагностики и разработки.

Он дополняет обычный вывод:

* подробностями выполнения;
* дополнительной информацией;
* диагностическими сообщениями;
* контекстом ошибок;
* внутренними этапами работы модулей.

Verbose Mode позволяет получить больше информации,
не изменяя сам процесс выполнения Toolkit.

Интерактивный Blueprint selector может иметь мало видимых отличий при
`--verbose`, потому что уже показывает необходимую пользователю информацию.
Добавлять искусственный verbose-шум для него не требуется.

---

## Future Dry-run / Preview Output

Dry-run / Preview запланирован и пока не реализован.

Его будущая задача — показывать планируемые изменения без их применения:

```text
Desired State
    ↓
Plan
    ↓
Presentation
```

Будущий Dry-run не должен изменять систему или создавать впечатление, что
изменения уже применены. Финальные статусы, CLI-формат, API, schema и Summary
ещё не спроектированы. Plan computation и presentation следует разделять там,
где это практично, сохраняя общую change-plan semantics для Preview и Apply.

---

# Секции

Основные компоненты Toolkit выводятся отдельными секциями.

Пример:

```text
==========================================
 Homebrew
==========================================
[ OK ] Homebrew already installed
```

Секции позволяют быстро определить, какой компонент
выполняется или уже обработан.

Каждый основной модуль должен по возможности использовать
единый формат секций.

---

# Статусы

Основные состояния отображаются единообразно:

```text
[ OK ]   Success
[WARN]   Warning
[ERROR]  Error
[....]   Action
[INFO]   Information
```

Конкретное содержимое сообщения определяется соответствующим
модулем, а формат сообщений — общей Logging System.

`[INFO]` может быть частью стандартного информационного вывода. Дополнительные
диагностические подробности показываются через `detail()` при `--verbose` и не
должны перегружать стандартный вывод.

---

# Summary

Текущая реализация использует несколько пользовательских вариантов Summary.

## Legacy lifecycle/count Summary

Check, Discovery и Bootstrap без Blueprint используют Summary жизненного цикла:

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

Summary показывает общий результат выполнения и позволяет
быстро оценить состояние системы без анализа всего вывода.

Headline определяется существующими lifecycle-счётчиками с таким приоритетом:

```text
ERROR_COUNT > 0
→ <Mode> completed with errors

иначе WARNING_COUNT > 0
→ <Mode> completed with warnings

иначе
→ <Mode> completed successfully
```

Ошибки имеют приоритет над предупреждениями. Success-only выполнение сохраняет
exit status `0`, warning-only — `1`, а выполнение с ошибкой — `2`. Отрисовка
Summary не меняет счётчики или итоговый lifecycle status.

Summary адаптируется под режим выполнения Toolkit:

```text
Check
Bootstrap
Discovery
```

Например:

```text
[ OK ] System check completed successfully
```

```text
[ OK ] Bootstrap completed successfully
```

```text
[ OK ] Discovery completed successfully
```

Для Discovery требуется дальнейшая корректировка детализации
Summary, чтобы итоговый вывод лучше отражал результаты
обнаружения без перегрузки общего вывода.

Эта задача находится в `TODO.md`.

## Blueprint selector Summary

Интерактивный selector перед Save показывает selection Summary: selected / total
для item-категорий и Yes / No для категорий настроек. Этот вывод помогает
подтвердить выбор и не описывает выполнение Bootstrap.

## Blueprint-aware Bootstrap Summary

Bootstrap с Blueprint после выполнения показывает выбранный scope и результат.
Например, значения ниже только иллюстративны:

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

Blueprint-aware Summary описывает выбранный scope восстановления. `Enabled`
означает «выбрано в Blueprint», а не «применено или изменено в этом запуске».

Summary будущего Dry-run / Preview ещё не спроектировано.

---

# Результат выполнения

Toolkit должен чётко разделять следующие ситуации:

### Success

Все необходимые операции выполнены успешно.

### Changed / Installed

Компонент был изменён или установлен существующим lifecycle.

### Unchanged / Skipped

Компонент уже находился в требуемом состоянии,
поэтому изменений не потребовалось.

### Warning

Работа продолжена, но обнаружена ситуация,
требующая внимания.

### Error

Операция не была успешно завершена.

Итоговый Summary должен отражать соответствующие
состояния выполнения.

`Planned` может стать состоянием будущего Dry-run / Preview, но сейчас не
является реализованным статусом Output System.

---

# Основные принципы

Output System должна обеспечивать:

* единый формат вывода;
* Quiet by Default;
* подробный Verbose Mode;
* будущее безопасное представление Dry-run / Preview;
* понятное разделение секций;
* единый набор статусов;
* обязательный итоговый Summary;
* Summary, соответствующий режиму выполнения;
* отсутствие лишнего технического шума;
* удобство диагностики;
* чёткое различие между выполненными и планируемыми изменениями.

---

# Архитектурное правило

> **Output explains the result of the operation.**
> **Logging defines how messages are represented and preserved.**

Output System отвечает за структуру и представление результата
для пользователя.

Logging System отвечает за типы сообщений, их формат,
сохранение истории и диагностическую информацию.

Бизнес-логика Toolkit не должна зависеть от способа отображения
результата.

```text
Module
   ↓
Result
   ↓
Output System
   ↓
User

Module
   ↓
Logging System
   ↓
Log History
```

Долгосрочно Result или Plan может отображаться через разные presentation layers:

```text
Result / Plan
    ↓
Presentation
    ├── CLI
    └── possible future presentation layers
```

Это не меняет текущий контракт и не требует реализации нового API или GUI.
