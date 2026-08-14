# Roadmap

## Назначение

Roadmap описывает последовательность развития
Mac Bootstrap Toolkit.

Архитектура проекта определяется в `docs/toolkit/ARCHITECTURE.md`.

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
- [x] machine-specific Generated Configuration
- [x] исключение `config/generated/` из публичного Git-репозитория

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

# Текущий фокус после 2.0.1 — Foundation Review / Reliability

**Статус: In Development**

Проверка и стабилизация существующей цепочки:

```text
Discovery → Generated Configuration → Bootstrap
```

- [ ] Полная проверка идемпотентности и повторного запуска
- [ ] Проверка согласованности Generated Configuration
- [ ] Проверка использования Bootstrap всех уже обнаруживаемых данных
- [ ] Единый Module Lifecycle и контракт exit codes
- [ ] Проверка важных edge cases
- [ ] Валидация конфигурации
- [ ] Regression tests, ShellCheck и code quality work

Это этап проверки существующего фундамента, а не новый Engine.

---

# Этап 5 — Blueprint Engine

**Статус: Planned**

Простой слой выбора между Discovery и Bootstrap. Discovery может
обнаружить больше компонентов, чем пользователь хочет перенести;
Blueprint определяет, какие из них действительно нужно восстановить.

- [ ] Blueprint format
- [ ] Выбор категорий и компонентов
- [ ] Выбор отдельных обнаруженных компонентов
- [ ] Component exclusions
- [ ] Blueprint validation
- [ ] Связь Blueprint с Generated Configuration и Bootstrap

Первый scope может охватывать Applications, Homebrew, VS Code,
Workspace и macOS Settings. Required / Optional component model,
parameter overrides, versioning и import / export не входят в
обязательный первый scope.

Blueprint не должен превращаться в сложный configuration framework
или требовать Profiles.

---

# Этап 6 — Dry-run / Preview

**Статус: Planned**

Безопасный предварительный просмотр действий Toolkit.

Dry-run позволяет определить, какие изменения Toolkit
собирается выполнить, не изменяя состояние системы.

Основная цель:

```text
Current State
      ↓
Bootstrap Checks
      ↓
Planned Changes
```

- [ ] Добавить `--dry-run`
- [ ] Выполнять проверки без изменений состояния
- [ ] Определять и единообразно показывать planned changes
- [ ] Поддержать Applications, VS Code, Workspace и macOS Settings
- [ ] Интегрировать Preview с Module Lifecycle, Logger и Summary
- [ ] Проверить соответствие Preview фактическому Bootstrap

Dry-run остаётся режимом существующего Bootstrap, а не отдельным
planner framework.

---

# Этап 7 — Bootstrap through Blueprint

**Статус: Planned**

Адаптация существующего Bootstrap Engine для применения только
состояния, выбранного в Blueprint.

- [ ] Передавать выбор Blueprint в Bootstrap
- [ ] Не применять обнаруженные, но не выбранные компоненты
- [ ] Сохранять безопасный и идемпотентный Bootstrap lifecycle

---

# Этап 8 — Verification

**Статус: Planned**

Подтверждение результата Bootstrap с использованием существующей
модели Check → Apply → Verify.

- [ ] Component verification
- [ ] Configuration verification
- [ ] Missing component detection
- [ ] Mismatch detection
- [ ] Итоговый verification status / report

Основная цель:

```text
Selected State
      ↓
 Bootstrap
      ↓
Verification
```

---

# Этап 9 — Coverage Expansion

**Статус: Planned**

Разумное расширение покрытия после завершения основного цикла.

## macOS Settings

- [ ] Добавлять только полезные и стабильные настройки
- [ ] Оценить Menu Bar, Mission Control, Login Items и Power Management

Кандидаты не являются обязательным полным списком; цель этапа — не
поддержка сотен `defaults`.

## VS Code

- [ ] Projects
- [ ] Workspaces
- [ ] Keybindings
- [ ] Snippets — при подтверждённой пользе

Profiles не относятся к ближайшему обязательному покрытию.

## Discovery

Новый Discovery-модуль приоритетен, когда его результат можно
использовать при восстановлении.

---

# Optional / Future Evolution

**Статус: Optional**

- Restore Engine — только если появится чёткая ответственность,
  принципиально не покрываемая цепочкой Blueprint → Bootstrap → Verification
- AI Assistant
- Profiles
- Machine Diff
- Secrets integrations
- Plugins
- GUI

Эти идеи не являются обязательными утверждёнными этапами. Отдельный
Restore Engine не исключён, но больше не считается обязательным
следующим звеном архитектуры.

---

# Quality & Reliability

**Статус: In Development (параллельное направление)**

Повышение надёжности и качества всей системы:

- [ ] Idempotency и error handling
- [ ] Configuration validation
- [ ] Regression tests
- [ ] ShellCheck и code quality
- [ ] Согласованность документации

Summary и вывод улучшаются только при выявлении конкретных проблем,
а не как самостоятельные стратегические цели.

---

# Продуктовая модель

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

Discovery фиксирует текущее состояние, Generated Configuration хранит
machine-specific результат, Blueprint выбирает нужное для переноса,
Preview показывает действия без изменений, Bootstrap безопасно
применяет выбранное состояние, а Verification подтверждает результат.

Toolkit не должен становиться универсальным macOS configuration
framework. Новая функция оправдана, если заметно улучшает обнаружение
состояния, выбор нужного, безопасное применение или проверку результата.
Внутренняя сложность не должна без необходимости переходить в
пользовательский workflow.

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
Foundation Review / Reliability
  ↓
Blueprint
  ↓
Dry-run / Preview
  ↓
Bootstrap using Blueprint
  ↓
Verification
  ↓
Coverage Expansion
  ↓
Optional / Future Evolution
```

Quality & Reliability развивается параллельно всем этапам.

---

# Правило Roadmap

Roadmap показывает **путь реализации**, а не полный список
архитектурных возможностей.

Архитектура проекта определяется в:

```text
docs/toolkit/ARCHITECTURE.md
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
