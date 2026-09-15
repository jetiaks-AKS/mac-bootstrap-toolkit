# Roadmap

## Назначение

Roadmap описывает последовательность развития Mac Bootstrap Toolkit.
Архитектура проекта определяется в `docs/toolkit/ARCHITECTURE.md`, ближайшие
технические задачи — в `TODO.md`, а история изменений — в `CHANGELOG.md`.

Roadmap показывает завершённые крупные этапы, выпущенный baseline 3.0.0,
завершённый scope 3.1.0 и утверждённое направление дальнейшего развития без
деталей реализации модулей.

---

# Этап 1 — Core

**Статус: Completed**

Фундамент Toolkit.

- [x] Common utilities, Logger и Preflight
- [x] Homebrew, Git, SSH и Terminal Core
- [x] Configuration Engine
- [x] Модульная структура и единый Bootstrap Engine

---

# Этап 2 — Discovery Engine

**Статус: Completed**

Автоматическое исследование поддерживаемого состояния текущего Mac.

## Applications и Development Environment

- [x] Homebrew packages, установленные пользователем
- [x] Homebrew casks
- [x] App Store applications
- [x] Git configuration
- [x] VS Code extensions и settings

## Workspace

- [x] Workspace folders
- [x] Git repositories и repository metadata
- [x] VS Code Workspace discovery и `vscode-workspaces.conf`

## macOS

- [x] Finder
- [x] Dock
- [x] Window Management
- [x] Keyboard
- [x] Trackpad
- [x] Screenshots

## Discovery lifecycle

- [x] Generated configuration publication
- [x] Collect → Validate → Serialize → Safe Publication
- [x] Сохранение предыдущего generated-состояния при обработанной ошибке
- [x] Различение допустимого отсутствия и ошибки наблюдения
- [x] Lifecycle/status propagation `0 / 1 / 2`
- [x] Независимый `workspace.conf` и grouped snapshot из четырёх производных
      Workspace-файлов

---

# Этап 3 — Generated Configuration

**Статус: Completed**

Локальное machine-specific описание обнаруженного окружения.

- [x] `config/generated/`
- [x] Applications, Git, VS Code, Workspace и macOS configuration
- [x] Приватное generated-состояние, исключённое из публичного Git-репозитория
- [x] Связь Discovery → Generated Configuration → Blueprint → Bootstrap
- [x] Safe publication и сохранение предыдущего валидного результата при
      обработанной ошибке
- [x] Валидация обязательного generated-ввода до потребления и мутации
- [x] Native non-executable Git configuration format
- [x] Grouped snapshot для `folders.conf`, `repositories.conf`,
      `vscode-workspaces.conf` и `inventory.conf`
- [x] Поддержка допустимого пустого состояния там, где оно определено
      контрактом компонента

---

# Этап 4 — Bootstrap Engine

**Статус: Completed**

Идемпотентное применение поддерживаемого Generated Configuration.

## Implemented scope

- [x] Core: Homebrew, Git, SSH и Terminal
- [x] Homebrew packages и casks
- [x] App Store applications
- [x] VS Code extensions и settings
- [x] Workspace folders и Git repositories
- [x] Global Git configuration
- [x] Finder, Dock, Window Management, Keyboard, Trackpad и Screenshots

## Consumer safety

- [x] Локальный Check → Apply → Verify lifecycle там, где состояние наблюдаемо
- [x] Различение ошибки наблюдения, отсутствия и несовпадения
- [x] Валидация обязательного generated-ввода до первой мутации
- [x] Отсутствие false success после ошибки mutation или verification
- [x] Workspace upfront validation до создания папок, clone или checkout
- [x] Application observation safety
- [x] Typed macOS observation, checked writes и post-write verification
- [x] Lifecycle/status propagation `0 / 1 / 2`

VS Code Workspace metadata обнаруживается, но Bootstrap-восстановление
`.code-workspace` не реализовано и отключено от production-оркестрации.

---

# Этап 5 — Blueprint Engine

**Статус: Completed**

Слой Desired Selection между Generated Configuration и Bootstrap.

- [x] Blueprint format, parser и validation
- [x] Приватный локальный `config/blueprint.conf`
- [x] Выбор отдельных компонентов и категорий
- [x] Интерактивный `--blueprint` selector
- [x] Безопасные edit, atomic save и cancel
- [x] Интеграция с Generated Configuration и Bootstrap
- [x] No-Blueprint all-inclusive compatibility
- [x] Warning `1` для stale selection
- [x] Error `2` и блокировка consumers для malformed Blueprint
- [x] Blueprint-aware Bootstrap Summary
- [x] E2E-проверка Blueprint workflow

Profiles, overrides, import/export и schema frameworks не входят в Blueprint
MVP.

---

# Этап 6 — Reliability & Release Hardening

**Статус: Completed**

Усиление надёжности уже реализованных Discovery, Blueprint и Bootstrap
перед release gate 3.0.0.

- [x] Discovery safe-publication lifecycle
- [x] Сохранение предыдущего generated-состояния при обработанных ошибках
- [x] Tri-state observation semantics для Bootstrap consumers
- [x] Upfront validation обязательного generated-ввода до mutation
- [x] Application consumer safety
- [x] Workspace Bootstrap validation до первой mutation
- [x] Typed macOS consumer validation и post-write verification
- [x] Корректная propagation статусов `0 / 1 / 2`
- [x] Warning-aware Summary без false success
- [x] Focused regression harnesses для критических Discovery, Blueprint,
      Bootstrap, Git, Workspace и macOS сценариев
- [x] Актуализация архитектурных и safety contracts документации

ShellCheck, единый test runner и CI не являются условиями выпуска 3.0.0
и могут развиваться отдельно после релиза.

---

# Этап 7 — Release 3.0.0

**Статус: Completed**

Toolkit 3.0.0 выпущен как Stable. Release commit `c36902d` входит в `develop`
и объединён в `main` merge-коммитом `8c8522c`; tag `v3.0.0` указывает на это
релизное состояние `main`.

- [x] Завершить финальное согласование документации
- [x] Провести единый финальный release validation
- [x] Разрешить вопрос release graph / release history
- [x] Установить Toolkit version 3.0.0
- [x] Финализировать CHANGELOG и release notes 3.0.0
- [x] Обновить release-specific документацию для 3.0.0
- [x] Выполнить merge `develop` → `main`
- [x] Проверить состояние `main` после merge
- [x] Создать tag `v3.0.0`
- [x] Завершить release verification

Состав завершённого релиза описан в `CHANGELOG.md`. Dry-run / Preview вошёл в
scope 3.1.0; Global Verification относится к Future / Optional.

---

# Этап 8 — Dry-run / Preview

**Статус: Completed (Release 3.1.0)**

Неизменяющий предварительный просмотр поведения существующего Bootstrap.

- [x] Добавить `--dry-run`
- [x] Выполнять checks без mutation
- [x] Формировать и показывать planned changes
- [x] Интегрировать Preview с текущими lifecycle, Logger и Summary
- [x] Поддержать Applications, VS Code, Workspace и macOS consumers
- [x] Сохранять соответствие Preview фактическому Bootstrap
- [x] Отделять вычисление плана от CLI-представления там, где это практично

Dry-run остаётся capability существующей Bootstrap-модели, а не новым planner
framework.

---

# Этап 9 — macOS Coverage Expansion

**Статус: In progress (9A–9E.1 implemented, Unreleased)**

Расширять полезное покрытие существующих категорий через Discovery → Generated
Configuration → Blueprint → Preview → Bootstrap с локальным Check → Apply → Verify.

- [x] 9A — Existing macOS Safety + Screenshots Destination: fixed current allowlist,
  safe scalar publication, EOF readers, mutation accounting, configured-directory lifecycle
- [x] 9B — Finder Expansion: 13 settings, fixed NewWindowTarget enum, safe
  unsupported-target omission, one restart after actual writes and final Check
- [x] 9C — Dock Expansion: 9 settings, strict orientation/mineffect enums, safe
  unsupported-enum omission and one restart after actual writes
- [x] 9D — Keyboard Expansion: 9 settings, existing bool/int contracts,
  typed verification and final Check without process restart
- [x] 9E.1 — Dock + Window Management Scalar Expansion: Dock 11 settings;
  `macos-windows` 4 confirmed NSGlobalDomain settings without process restart
- [x] 9E.2 — WindowManager Lifecycle Research: lifecycle исследован;
  реализация четырёх tiling preferences deferred
- [x] 9E.3 — Trackpad Reliability: supported scope сокращён до двух primary
  stored bool preferences; tracking speed и device synchronization deferred
- [ ] 9F — Menu Bar / Control Center Compatibility: сначала доказать owner,
  безопасное чтение/запись и reload; uncertain settings не объявлять supported
- [ ] 9G — Secondary scalar settings, только при низком риске
- [ ] 9H — Final integration, compatibility, docs/tests

9A не добавляет новых preferences, типов или Blueprint categories. 9B добавляет
ровно шесть Finder preferences в существующую категорию; 9C — четыре Dock preferences.
9D добавляет семь Keyboard preferences. 9E.1 добавляет два Dock preferences и
четыре Window Management preferences. 9E.2 оставляет WindowManager tiling deferred;
9E.3 сохраняет только два надёжных Trackpad bool records. Остальные фазы требуют
отдельной реализации. Private databases, UI automation и raw
machine-specific metadata не входят в scope. Generic settings/planner engines
не являются требованием.

---

# Этап 10 — Remaining Coverage Expansion

**Статус: Planned**

- [ ] Bootstrap-восстановление `.code-workspace`
- [ ] VS Code Keybindings
- [ ] Snippets при подтверждённой пользе
- [ ] Projects после определения конкретной продуктовой модели

Discovery expansion приоритетен, когда обнаруженное состояние имеет реальный
restoration consumer или ясную продуктовую ценность. Эти задачи не входят в 9A.

---

# Optional / Future Evolution

**Статус: Optional**

- Global Verification: optional aggregate post-Bootstrap report; локальный Verify
  остаётся обязательным для наблюдаемых результатов мутаций
- Energy / pmset и Login Items — отдельная проверка privileges, hardware и API
- Shell, Aliases, Terminal и SSH discovery/restoration после оценки пользы
- Discovery Report; ShellCheck, единый test runner и CI по отдельной задаче
- Restore Engine — только если появится ответственность, которую нельзя чисто
  покрыть существующей цепочкой Blueprint → Bootstrap
- AI Assistant
- Profiles
- Machine Diff
- Secrets integrations
- Plugins
- GUI

Эти идеи не являются утверждёнными roadmap stages.

---

# Продуктовая модель

Модель релиза 3.0.0 Stable:

```text
Discovery
    ↓
Generated Configuration
    ↓
Blueprint
    ↓
Bootstrap
```

Модель релиза 3.1.0:

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
```

Preview является неизменяющей capability вокруг существующей Bootstrap planning
и check-логики. Global Verification остаётся optional post-Bootstrap направлением и не
входит в релиз 3.1.0; ни одна из возможностей не требует заранее вводить
heavyweight framework.

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
Reliability & Release Hardening
  ↓
Release 3.0.0
  ↓
Dry-run / Preview
  ↓
Release 3.1.0
  ↓
macOS Coverage Expansion
  ↓
Remaining Coverage Expansion
  ↓
Optional / Future Evolution
```

---

# Правило Roadmap

Completed stages содержат только реализованный baseline. Нереализованные
возможности остаются в planned или optional scope, а история завершённых
изменений хранится в `CHANGELOG.md`.
