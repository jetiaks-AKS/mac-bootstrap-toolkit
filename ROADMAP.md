# Roadmap

## Назначение

Roadmap описывает последовательность развития Mac Bootstrap Toolkit.
Архитектура проекта определяется в `docs/toolkit/ARCHITECTURE.md`, ближайшие
технические задачи — в `TODO.md`, а история изменений — в `CHANGELOG.md`.

Roadmap показывает завершённые крупные этапы, текущий release gate и
утверждённое направление дальнейшего развития без деталей реализации модулей.

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
- [x] Finder, Dock, Keyboard, Trackpad и Screenshots

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

**Статус: In Progress**

Конечный release gate для ещё не выпущенной версии 3.0.0.

- [x] Завершить финальное согласование документации
- [x] Провести единый финальный release validation
- [x] Разрешить вопрос release graph / release history
- [ ] Установить Toolkit version 3.0.0
- [x] Финализировать CHANGELOG и release notes 3.0.0
- [x] Обновить release-specific документацию для 3.0.0
- [ ] Выполнить merge `develop` → `main`
- [ ] Проверить состояние `main` после merge
- [ ] Создать tag `v3.0.0`
- [ ] Завершить release verification

Ни один из этих незавершённых пунктов не означает, что 3.0.0 уже выпущена.

---

# Этап 8 — Dry-run / Preview

**Статус: Planned**

Неизменяющий предварительный просмотр поведения существующего Bootstrap.

- [ ] Добавить `--dry-run`
- [ ] Выполнять checks без mutation
- [ ] Формировать и показывать planned changes
- [ ] Интегрировать Preview с текущими lifecycle, Logger и Summary
- [ ] Поддержать Applications, VS Code, Workspace и macOS consumers
- [ ] Сохранять соответствие Preview фактическому Bootstrap
- [ ] Отделять вычисление плана от CLI-представления там, где это практично

Dry-run остаётся capability существующей Bootstrap-модели, а не новым planner
framework.

---

# Этап 9 — Global Verification

**Статус: Planned**

Локальная post-apply verification уже используется текущими Bootstrap-модулями
там, где она реализована. Этот будущий этап относится к общей post-Bootstrap
проверке выбранного Desired State.

- [ ] Selected-state verification
- [ ] Missing component detection
- [ ] Mismatch detection
- [ ] Aggregate verification status и report

Отдельный сложный Verification Engine не является заранее установленным
требованием.

---

# Этап 10 — Coverage Expansion

**Статус: Planned**

Расширение покрытия после выпуска 3.0.0 при наличии ясной продуктовой пользы.

## macOS и system environment

- [ ] Дополнительные полезные Finder, Dock и system preferences
- [ ] Menu Bar, Mission Control, Login Items и Power Management
- [ ] Shell, Aliases, Terminal и SSH discovery/restoration, если они будут
      признаны полезными

## VS Code

- [ ] Bootstrap-восстановление `.code-workspace`
- [ ] Keybindings
- [ ] Snippets при подтверждённой пользе
- [ ] Projects после определения конкретной продуктовой модели

## Discovery и quality tooling

- [ ] Discovery Report, если он даст самостоятельную пользовательскую ценность
- [ ] ShellCheck/static analysis, единый test runner и CI по мере необходимости

Discovery expansion приоритетен, когда обнаруженное состояние имеет реальный
restoration consumer или ясную продуктовую ценность. Не следует создавать
preference registry/schema framework только ради потенциального роста macOS
coverage; scalable catalog стоит рассматривать лишь тогда, когда реальный рост
сделает текущий explicit-подход существенно сложным в сопровождении.

---

# Optional / Future Evolution

**Статус: Optional**

- Restore Engine — только если появится ответственность, которую нельзя чисто
  покрыть цепочкой Blueprint → Bootstrap → Global Verification
- AI Assistant
- Profiles
- Machine Diff
- Secrets integrations
- Plugins
- GUI

Эти идеи не являются утверждёнными roadmap stages.

---

# Продуктовая модель

Текущая модель в `develop`:

```text
Discovery
    ↓
Generated Configuration
    ↓
Blueprint
    ↓
Bootstrap
```

Будущая post-3.0 модель:

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
Global Verification
```

Preview будет неизменяющей capability вокруг существующей Bootstrap planning
и check-логики. Global Verification станет общей post-Bootstrap проверкой; ни
одна из возможностей не требует заранее вводить heavyweight framework.

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
Global Verification
  ↓
Coverage Expansion
  ↓
Optional / Future Evolution
```

---

# Правило Roadmap

Completed stages содержат только реализованный baseline. Нереализованные
возможности остаются в planned или optional scope, а история завершённых
изменений хранится в `CHANGELOG.md`.
