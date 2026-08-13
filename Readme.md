# Mac Bootstrap Toolkit

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
````

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
* [x] `--verbose`
* [x] `--help`
* [x] `--version`

---

## Развитие проекта

Текущая версия 2.0.1 формирует стабильную основу для дальнейшего развития Toolkit.

Следующие архитектурные этапы:

Discovery
     ↓
Generated Configuration
     ↓
Blueprint
     ↓
Verification
     ↓
Bootstrap
     ↓
Restore

Blueprint, Verification, Restore и AI Assistant являются следующими этапами развития проекта и не являются частью текущего стабильного функционала.

Подробный план развития описан в `ROADMAP.md`.

---

## Документация

Документация проекта разделена по назначению:

- `docs/getting-started/` — начало работы и основные сценарии.
- `docs/toolkit/` — архитектура и устройство Toolkit.
- `docs/macos/` — документация по macOS.
- `docs/git/` — Git и рабочие процессы.
- `docs/ideas/` — идеи и направления развития.

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

```
