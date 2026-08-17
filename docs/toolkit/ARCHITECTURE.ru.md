# Архитектура Mac Bootstrap Toolkit

[English](ARCHITECTURE.md) | Русский

## Назначение

Mac Bootstrap Toolkit — модульная система для анализа, описания,
проверки и воспроизводимого восстановления рабочего окружения macOS.

Основная цель — получить возможность исследовать существующий Mac,
сформировать описание его окружения и использовать это описание
для подготовки другого Mac с минимальным количеством ручных действий.

---

## Текущая архитектура `develop`

```text
Current Mac
    ↓
Discovery
    ↓
Generated Configuration
    ↓
Blueprint
    ↓
Bootstrap
    ↓
Target Mac
```

Это реализованная и E2E-проверенная архитектура ветки `develop`. Blueprint ещё
не входит в стабильный релиз 2.0.1. Без `config/blueprint.conf` Bootstrap
сохраняет legacy-поведение и применяет весь поддерживаемый generated scope.

Будущая архитектура после реализации Dry-run / Preview и Verification:

```text
Discovery
    ↓
Generated Configuration
    ↓
Blueprint
    ↓
Dry-run / Preview
    ↓
Bootstrap
    ↓
Verification
```

### Что означает каждый уровень

**Discovery** — определяет, что существует на текущем Mac.

**Generated Configuration** — сохраняет обнаруженное состояние
в воспроизводимом машинно-читаемом виде.

**Blueprint** — выбирает категории и отдельные обнаруженные компоненты,
которые входят в целевой scope восстановления. Фактические значения остаются
в Generated Configuration.

**Dry-run / Preview** — запланированный безопасный режим Bootstrap, который
будет показывать предполагаемые изменения без их применения.

**Bootstrap** — применяет необходимые изменения.

**Verification** — запланированное подтверждение результата после Bootstrap.

---

# Основные архитектурные принципы

## Discovery → Generated Configuration → Blueprint → Bootstrap

Это основной контракт Toolkit.

```text
Current Mac
    │
    ▼
Discovery
    │
    ▼
config/generated/
    │
    ▼
Blueprint
    │
    ▼
Bootstrap
```

Discovery является источником фактического состояния.

Blueprint хранит выбор, но не дублирует обнаруженные значения. Bootstrap
использует результаты Discovery через этот выбор и не должен содержать
дублирующие значения пользовательской конфигурации.

Поэтому изменение обнаруженной настройки должно по возможности
происходить через конфигурацию, а не через изменение Bootstrap-кода.

---

## Observed State → Desired State

Toolkit разделяет два понятия:

**Observed State** — то, что реально обнаружено на текущем Mac.

**Desired State** — то, что должно быть на целевом Mac.

Их связывает Blueprint:

```text
Observed State
      │
      ▼
   Blueprint
      │
      ▼
Desired State
```

Generated Configuration описывает Observed State, а Blueprint формирует
выбранный Desired State для Bootstrap.

---

# Основные компоненты

## Core

Фундаментальные сервисы Toolkit:

* common utilities;
* logging;
* preflight;
* Homebrew;
* Git;
* SSH;
* Terminal;
* configuration services.

Core предоставляет общую инфраструктуру и не должен содержать
логику конкретного пользовательского окружения.

---

## Discovery Engine

Отвечает за исследование текущего Mac.

Области Discovery включают:

* приложения;
* Homebrew;
* Git;
* VS Code;
* Workspace;
* macOS Settings;
* другие компоненты рабочего окружения.

Результат сохраняется в:

```text
config/generated/
```

---

## Configuration Engine

Предоставляет общие механизмы работы с конфигурацией Toolkit.

Он отвечает за чтение, получение и обработку конфигурационных данных,
но не определяет бизнес-логику отдельных модулей.

Generated Configuration содержит machine-specific данные
об обнаруженном окружении и не является частью публичного
Git-состояния проекта.

Generated-файлы являются источником данных об обнаруженном состоянии для
Blueprint и Bootstrap. Для данных приложений используются простые списки, для
глобального Git-состояния — нативный невыполняемый формат Git configuration, а
для Workspace repositories — секционная конфигурация, читаемая через
Configuration Engine. Форматы экспортёров и потребителей должны оставаться
совместимыми.

`config/generated/git.conf` разбирается как данные через `git config` и никогда
не выполняется через `source` или `eval`. Он содержит только поддерживаемый
scope глобальной Git configuration: `user.name`, `user.email`,
`init.defaultBranch`, `pull.rebase` и `core.editor`. Настроенные и отсутствующие
значения различаются. Повреждённая или неподдерживаемая generated-конфигурация
блокирует изменение Git-состояния, а не интерпретируется частично.

Discovery безопасно публикует этот файл только после успешного наблюдения и
сериализации; при ошибке предыдущее generated-состояние сохраняется. После
старого shell assignment format необходимо заново выполнить Discovery:
автоматическая миграция этого локального файла не предусмотрена.

---

## Blueprint Engine

Формирует выбранный scope восстановления на основе обнаруженного состояния.

Реализованный Blueprint позволяет:

* выбирать категории и отдельные обнаруженные компоненты;
* валидировать сохранённый выбор;
* фильтровать Bootstrap без дублирования generated-значений;
* сохранять локальный приватный выбор в `config/blueprint.conf`.

---

## Verification Engine

Verification запланирован и пока не реализован. После реализации он будет
подтверждать соответствие результата Bootstrap выбранному состоянию.

```text
Current State
      │
      ▼
Verification
      │
      ▼
Differences
```

Verification не должен изменять состояние.

---

## Bootstrap Engine

Применяет целевую конфигурацию.

Основной принцип работы:

```text
Check
  ↓
Apply
  ↓
Verify
```

Bootstrap должен быть идемпотентным:

```text
Первый запуск → применить изменения

Повторный запуск → обнаружить уже настроенное → пропустить
```

Основные области:

* Core;
* Applications;
* Workspace;
* VS Code;
* macOS Settings.

---

## Dry-run Mode

Dry-run запланирован и пока не реализован. Он будет режимом работы Bootstrap
Engine, а не отдельным архитектурным Engine.

Он будет позволять предварительно определить, какие изменения
Bootstrap собирается выполнить, без фактического изменения системы.

Основной принцип:

```text
Current State
      ↓
Bootstrap Checks
      ↓
Planned Changes
```

Dry-run должен использовать существующий Module Lifecycle,
проверки и Logger, но вместо применения изменений формировать
предварительный результат выполнения.

Основные требования:

* не изменять состояние системы;
* показывать планируемые изменения;
* использовать единый формат вывода;
* учитывать результаты проверок модулей;
* использовать существующий механизм логирования;
* формировать понятный Summary;
* по возможности обеспечивать соответствие результата Dry-run
  последующему реальному Bootstrap.

Dry-run не заменяет Bootstrap и не определяет Desired State.

Его задача — безопасно показать предполагаемое выполнение
существующего Bootstrap workflow.

---

## Optional Restore Direction

Отдельный Restore Engine не является обязательным следующим этапом. Он остаётся
optional-направлением только для ответственности, которую нельзя покрыть
цепочкой Blueprint → Bootstrap → Verification.

---

## AI Assistant

AI Assistant остаётся optional-направлением автоматизации.

Он не заменяет существующие компоненты, а использует их данные
и результаты для:

* анализа;
* диагностики;
* формирования Blueprint;
* объяснения различий;
* рекомендаций;
* помощи при восстановлении.

---

# Workspace

Workspace является отдельной областью рабочего окружения.

Он включает:

* директории;
* Git repositories;
* remotes;
* branches;
* VS Code Projects;
* VS Code Workspaces.

Архитектура Workspace:

```text
Discovery
    ↓
Workspace State
    ↓
Blueprint
    ↓
Bootstrap
```

В будущем Dry-run / Preview будет выполняться перед Bootstrap, а Verification —
после него.

---

# macOS Settings

Настройки macOS используют общий принцип:

```text
macOS
  ↓
Discovery
  ↓
config/generated/macos/
  ↓
Blueprint
  ↓
Bootstrap
  ↓
macOS
```

Будущий Dry-run для macOS Settings должен определять предполагаемые изменения
до их применения.

Новые настройки должны по возможности добавляться через generated
configuration и общий механизм применения, а не через дублирование
одинаковой логики в отдельных модулях.

---

# Расширяемость

Текущий жизненный цикл нового поддерживаемого компонента:

```text
Discovery
    ↓
Generated Configuration
    ↓
Blueprint
    ↓
Bootstrap
```

Будущий цикл после реализации Preview и Verification:

```text
Generated Configuration
    ↓
Blueprint
    ↓
Dry-run / Preview
    ↓
Bootstrap
    ↓
Verification
```

Добавление нового компонента не должно требовать переписывания
существующих компонентов.

---

# Статусы реализации

Архитектура описывает **целевую систему**, а не только то,
что уже реализовано.

Компоненты могут иметь статус:

```text
Planned
    ↓
In Development
    ↓
Implemented
    ↓
Verified
```

Режимы работы Toolkit могут развиваться независимо от основных
архитектурных компонентов.

Текущий статус определяется в:

* `ROADMAP.md` — этапы проекта;
* `TODO.md` — ближайшие задачи;
* `CHANGELOG.md` — история изменений.

`ARCHITECTURE.md` изменяется только при изменении самой архитектуры,
а не при каждом добавлении очередной функции.

---

# Главный принцип

> **Discover → Describe → Select → Bootstrap**

Toolkit должен превращать текущее рабочее окружение в воспроизводимый выбранный
scope, который можно безопасно применить на другом Mac.

После реализации Dry-run будет безопасным режимом выполнения Bootstrap, а
Verification будет подтверждать результат после применения.

```text
Discover
    ↓
Describe
    ↓
Select
    ↓
Bootstrap
```
