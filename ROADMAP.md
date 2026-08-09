# Roadmap

## Назначение

Roadmap описывает последовательность развития
Mac Bootstrap Toolkit.

Архитектура проекта определяется в `ARCHITECTURE.md`.

Roadmap определяет:

- какие этапы уже завершены;
- что находится в текущем развитии;
- что планируется дальше;
- в каком порядке развивается система.

Roadmap не заменяет архитектурную документацию и не описывает
детали реализации отдельных модулей.

---

# Этап 1 — Core

**Статус: Completed**

Фундамент Toolkit.

- [x] Common utilities
- [x] Logger
- [x] Preflight
- [x] Homebrew
- [x] Git
- [x] SSH
- [x] Terminal
- [x] Configuration Engine
- [x] базовая структура модулей
- [x] единый Bootstrap Engine

---

# Этап 2 — Discovery Engine

**Статус: Completed**

Автоматическое исследование текущего Mac.

## Applications

- [x] Homebrew Packages
- [x] Homebrew Casks
- [x] App Store

## Development Environment

- [x] Git
- [x] VS Code Extensions
- [x] VS Code Settings

## Workspace

- [x] Workspace folders
- [x] Git repositories
- [x] Repository metadata
- [ ] VS Code Projects
- [ ] VS Code Workspaces

## macOS

- [x] Finder
- [x] Dock
- [x] Keyboard
- [x] Trackpad
- [x] Screenshots
- [ ] SSH
- [ ] Terminal
- [ ] Shell
- [ ] Aliases
- [ ] Menu Bar
- [ ] Mission Control
- [ ] Login Items
- [ ] Power Management

## Discovery Infrastructure

- [x] Generated configuration
- [x] Discovery modules
- [x] Configuration export
- [x] базовый Discovery workflow
- [ ] Discovery Report
- [ ] расширенная валидация Discovery

Незавершённые пункты являются расширением Discovery Engine,
а не препятствием для его базового завершения.

---

# Этап 3 — Generated Configuration

**Статус: Completed**

Формирование воспроизводимого описания обнаруженного окружения.

- [x] `config/generated/`
- [x] Applications configuration
- [x] Git configuration
- [x] VS Code configuration
- [x] Workspace configuration
- [x] macOS Settings configuration
- [x] единый принцип Discovery → Generated Configuration → Bootstrap
- [x] устранение дублирования пользовательских настроек в Bootstrap-коде

---

# Этап 4 — Bootstrap Engine

**Статус: Completed**

Восстановление рабочего окружения на основе Generated Configuration.

## Core

- [x] Homebrew
- [x] Git
- [x] SSH
- [x] Terminal

## Applications

- [x] Homebrew Packages
- [x] Homebrew Casks
- [x] App Store

## VS Code

- [x] Extensions
- [x] Settings
- [ ] Projects
- [ ] Workspaces
- [ ] Keybindings
- [ ] Snippets
- [ ] Profiles

## Workspace

- [x] Folders
- [x] Git repositories
- [x] Remote verification
- [x] Branch verification
- [x] Repository restoration
- [ ] VS Code Projects
- [ ] VS Code Workspaces

## macOS Settings

- [x] Finder
- [x] Dock
- [x] Keyboard
- [x] Trackpad
- [x] Screenshots
- [ ] дополнительные системные настройки

Незавершённые пункты являются расширением Bootstrap Engine
и не меняют завершённость базового Bootstrap workflow.

---

# Этап 5 — Blueprint Engine

**Статус: Planned**

Формирование целевого профиля рабочего окружения.

- [ ] Blueprint format
- [ ] Component selection
- [ ] Required / Optional components
- [ ] Parameter overrides
- [ ] Component exclusions
- [ ] Blueprint validation
- [ ] Blueprint versioning
- [ ] Blueprint import / export

Основная цель:

```text
Observed State
      ↓
   Blueprint
      ↓
Desired State
````

Blueprint должен стать источником целевого состояния,
а не заменять существующий Discovery Engine.

---

# Этап 6 — Verification Engine

**Статус: Planned**

Проверка соответствия текущего Mac целевому состоянию.

* [ ] State comparison
* [ ] Component verification
* [ ] Configuration verification
* [ ] Missing component detection
* [ ] Configuration mismatch detection
* [ ] Verification report
* [ ] Verification summary

Основная цель:

```text
Current State
      ↓
Verification
      ↓
Differences
```

---

# Этап 7 — Restore Engine

**Статус: Planned**

Полное воспроизводимое восстановление рабочего окружения.

* [ ] Restore workflow
* [ ] Dependency handling
* [ ] Restore ordering
* [ ] Restore verification
* [ ] Recovery from partial failure
* [ ] Restore report
* [ ] Restore summary

Основная цель:

```text
Blueprint
    ↓
Verification
    ↓
Bootstrap
    ↓
Restore
    ↓
Verified Mac
```

---

# Этап 8 — AI Assistant

**Статус: Planned**

Интеллектуальный слой поверх существующей архитектуры.

* [ ] Environment analysis
* [ ] Configuration analysis
* [ ] Blueprint generation
* [ ] Difference explanation
* [ ] Troubleshooting
* [ ] Restore assistance
* [ ] Recommendations
* [ ] Automated remediation suggestions

AI Assistant не заменяет существующие компоненты Toolkit,
а использует их данные и результаты.

---

# Этап 9 — Quality & Reliability

**Статус: In Development**

Повышение надёжности и качества всей системы.

* [ ] Полная проверка идемпотентности модулей
* [ ] Расширенная обработка ошибок
* [ ] Единый стиль сообщений
* [ ] Расширение Verbose Mode
* [ ] Улучшение Summary
* [ ] Конфигурационная валидация
* [ ] Regression tests
* [ ] ShellCheck / code quality
* [ ] Documentation review

Quality & Reliability развивается параллельно
основным архитектурным этапам.

---

# Текущий фокус

Версия **2.0.0 Stable** завершает базовый цикл:

```text
Discovery
    ↓
Generated Configuration
    ↓
Bootstrap
```

Следующим архитектурным этапом является **Blueprint Engine**.

Техническая стабилизация и улучшение существующих компонентов
продолжаются параллельно через `TODO.md`.

---

# Порядок развития

```text
Core
  ↓
Discovery
  ↓
Generated Configuration
  ↓
Bootstrap
  ↓
Blueprint
  ↓
Verification
  ↓
Restore
  ↓
AI Assistant
```

Quality & Reliability развивается параллельно всем этапам.

---

# Правило Roadmap

Roadmap показывает **путь реализации**, а не полный список
архитектурных возможностей.

Архитектура проекта определяется в:

```text
ARCHITECTURE.md
```

Конкретные ближайшие технические задачи находятся в:

```text
TODO.md
```

История завершённых изменений находится в:

```text
CHANGELOG.md
```

При добавлении новой функции Roadmap обновляется только в части
её статуса и этапа реализации.

Структура целевой архитектуры при этом не изменяется.

````
