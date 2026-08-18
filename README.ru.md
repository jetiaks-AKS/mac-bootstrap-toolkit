# Mac Bootstrap Toolkit

[English](README.md) | Русский

Автоматизированная подготовка и восстановление рабочего окружения macOS.

**Текущая версия: 2.0.1 Stable**

---

## Назначение

Mac Bootstrap Toolkit помогает воспроизводимо подготовить рабочее окружение macOS.

Toolkit может:

- проанализировать существующее окружение;
- автоматически сформировать его конфигурацию;
- использовать эту конфигурацию для Bootstrap нового Mac;
- проверять текущее состояние поддерживаемых компонентов;
- при необходимости восстанавливать их.

Главная идея проекта — переносить не всю систему, а именно **рабочее пространство пользователя**.

---

## Основной workflow

Стабильный релиз 2.0.1 использует:

```text
Existing Mac
     ↓
 Discovery
     ↓
Generated Configuration
     ↓
 Bootstrap
     ↓
Ready-to-Work Mac
```

Текущая ветка `develop`, в которой Blueprint планируется как главная функция
будущего релиза 3.0.0, использует:

```text
Discovery
     ↓
Generated Configuration
     ↓
Blueprint
     ↓
Bootstrap
```

Discovery автоматически анализирует существующее окружение и формирует конфигурацию, которую затем использует Bootstrap.

Этот подход позволяет постепенно развивать Toolkit от простого Bootstrap-инструмента к полноценной системе воспроизводимого рабочего окружения.

---

## Возможности

### Bootstrap

* Homebrew Packages;
* Homebrew Casks;
* приложения App Store;
* Git;
* VS Code Extensions;
* VS Code Settings;
* настройки macOS;
* Workspace Folders;
* Git Repositories;
* Git Branch Restoration.

### Discovery

* Homebrew Packages;
* Homebrew Casks;
* Git Configuration;
* VS Code Extensions;
* VS Code Settings;
* настройки macOS;
* структура Workspace;
* Workspace Folders;
* Git Repositories;
* Workspace Inventory.

Результаты Discovery сохраняются в:

```text
config/generated/
```

В ветке `develop` Blueprint добавляет необязательный локальный слой выбора.
После Discovery команда `./bootstrap.sh --blueprint` создаёт или изменяет
`config/blueprint.conf`, а Bootstrap обрабатывает только выбранные категории и
компоненты. Файл приватный, исключён из Git и не дублирует фактические значения
из `config/generated/`. Без Blueprint сохраняется полный scope Bootstrap.

При активном Blueprint итоговый Bootstrap Summary компактно показывает
selected/total counts и категории настроек Enabled/Skipped без списка отдельных
компонентов.

---

## Принципы

* **Discovery First** — существующее окружение сначала анализируется, а не описывается вручную.
* **Generated Configuration** — результаты Discovery используются как конфигурация для Bootstrap.
* **Idempotent** — повторный запуск не должен выполнять ненужные изменения.
* **Verify After Apply** — после применения изменений состояние проверяется повторно.
* **Self-Healing** — поддерживаемые компоненты могут автоматически восстанавливаться.
* **Quiet by Default** — стандартный вывод остаётся компактным.
* **Verbose When Needed** — `--verbose` показывает подробную информацию.
* **Modular Architecture** — функциональность разделена на независимые модули.

---

## CLI

Проверка системы:

```bash
./bootstrap.sh --check
```

Discovery текущего окружения:

```bash
./bootstrap.sh --discover
```

Bootstrap рабочего окружения:

```bash
./bootstrap.sh --bootstrap
```

Необязательный выбор компонентов в ветке `develop`:

```bash
./bootstrap.sh --blueprint
```

Подробный вывод:

```bash
./bootstrap.sh --check --verbose
./bootstrap.sh --discover --verbose
./bootstrap.sh --bootstrap --verbose
```

Дополнительно:

```bash
./bootstrap.sh --help
./bootstrap.sh --version
```

---

## Структура

```text
.
├── config/
│   └── generated/
├── docs/
├── modules/
├── scripts/
├── settings/
└── bootstrap.sh
```

Основная логика Toolkit находится в `modules/`.

Автоматически обнаруженная конфигурация находится в:

```text
config/generated/
```

---

## Реализовано

### Core

* [x] Logging
* [x] Preflight Checks
* [x] Homebrew
* [x] Git
* [x] SSH
* [x] Terminal

### Bootstrap

* [x] Applications
* [x] VS Code
* [x] macOS Settings
* [x] Workspace Folders
* [x] Git Repository Restoration
* [x] Git Branch Restoration

### Discovery

* [x] Homebrew
* [x] Git
* [x] VS Code
* [x] macOS
* [x] Workspace
* [x] Generated Configuration
* [x] Workspace Inventory

### CLI

* [x] `--check`
* [x] `--discover`
* [x] `--bootstrap`
* [x] `--blueprint` (ветка `develop`, ещё не выпущено)
* [x] `--verbose`
* [x] `--help`
* [x] `--version`

---

## Развитие проекта

Текущая версия 2.0.1 формирует стабильную основу для дальнейшего развития Toolkit.
В ветке `develop` уже реализованы формат Blueprint, parser, validation,
интерактивный selector и фильтрация Bootstrap. Blueprint MVP завершён и прошёл
полную E2E-проверку в `develop`, но эти изменения ещё не входят в стабильный
релиз 2.0.1. Blueprint планируется как главная функция будущего релиза 3.0.0;
версия 3.0.0 ещё не выпущена.

Целевая модель после реализации следующих архитектурных этапов:

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

Dry-run и Verification пока не реализованы. Restore и AI Assistant остаются
возможными будущими направлениями.

Подробный план развития описан в `ROADMAP.md`.

---

## Документация

Документация проекта разделена по назначению:

- `docs/getting-started/` — начало работы и основные сценарии.
- `docs/toolkit/` — архитектура и устройство Toolkit.
- `docs/git/` — Git и рабочие процессы.

Основные документы:

- `ROADMAP.md` — план развития проекта.
- `TODO.md` — текущие технические задачи.
- `CHANGELOG.md` — история изменений.

---

## Статус

| Параметр     | Значение   |
| ------------ | ---------- |
| Статус       | **Stable** |
| Версия       | **2.0.1**  |
| Платформа    | macOS      |
| Язык         | Bash       |
| Архитектура  | Модульная  |
| Конфигурация | Generated  |
| Лицензия     | MIT        |

---

Mac Bootstrap Toolkit развивается как система воспроизводимого рабочего окружения macOS.

Версия **2.0.1 Stable** фиксирует стабильную основу Toolkit:
**Discovery → Generated Configuration → Bootstrap**.

Эта архитектура является основой для дальнейшего развития проекта.
