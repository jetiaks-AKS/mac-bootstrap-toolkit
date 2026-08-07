# Mac Bootstrap Toolkit

Автоматизированная платформа для анализа, подготовки и восстановления рабочего окружения macOS.

Текущая версия: **1.2.0-dev**.

---

## Назначение

Mac Bootstrap Toolkit предназначен для создания полностью воспроизводимого рабочего окружения macOS.

Проект постепенно развивается от инструмента автоматической настройки нового Mac к единой платформе управления жизненным циклом рабочего пространства:

```text
Discovery
    │
    ▼
Blueprint
    │
    ▼
Bootstrap
    │
    ▼
Verification
    │
    ▼
Restore
```

Каждый компонент развивается независимо, но использует общую архитектуру Toolkit.

---

## Возможности

### Bootstrap Engine

- автоматическая установка Homebrew Packages;
- автоматическая установка Homebrew Casks;
- установка приложений App Store;
- установка расширений VS Code;
- применение настроек VS Code;
- настройка macOS;
- восстановление Workspace (в разработке);
- Quiet Mode по умолчанию;
- режим Verbose (`--verbose`);
- автоматическое восстановление Homebrew Casks (Self-Healing);
- безопасный повторный запуск (Idempotent);
- итоговый Summary с результатами выполнения.

### Discovery Engine

- экспорт Homebrew Packages;
- экспорт Homebrew Casks;
- экспорт конфигурации Git;
- экспорт настроек VS Code;
- экспорт настроек macOS;
- анализ Workspace;
- экспорт структуры каталогов;
- экспорт Git-репозиториев;
- экспорт VS Code Projects;
- экспорт VS Code Workspaces;
- генерация конфигурации для Bootstrap.

---

## Принципы

- модульная архитектура;
- идемпотентность (Idempotent);
- Discovery First;
- Verify After Apply;
- Self-Healing;
- Quiet by Default;
- Verbose When Needed;
- минимум ручных действий;
- понятный код;
- подробное логирование;
- документация для каждого модуля.

---

## Структура

```text
.
├── config/
├── docs/
├── modules/
├── scripts/
├── settings/
└── bootstrap.sh
```

---

## Документация

Подробная информация находится в каталоге `docs/`.

- Getting Started
- Roadmap
- Toolkit Architecture
- Module Documentation

---

## Реализовано

### Core Engine

- [x] Logging
- [x] Preflight
- [x] Homebrew
- [x] Git
- [x] SSH
- [x] Terminal

### Bootstrap Engine

- [x] Homebrew Packages
- [x] Homebrew Casks
- [x] App Store
- [x] VS Code Extensions
- [x] VS Code Settings
- [x] macOS Settings
- [x] Workspace Folders

### Discovery Engine

- [x] Homebrew
- [x] Git
- [x] VS Code
- [x] macOS
- [x] Workspace

### CLI

- [x] `--check`
- [x] `--discover`
- [x] `--bootstrap`
- [x] `--help`
- [x] `--version`

---

| Параметр | Значение |
|----------|----------|
| Статус | 🚧 Active Development |
| Версия | **1.2.0-dev** |
| Платформа | macOS |
| Язык | Bash |
| Архитектура | Модульная |
| Лицензия | MIT |

---

Текущий этап разработки — развитие **Bootstrap Workspace** и дальнейшая интеграция **Discovery Engine** с Bootstrap.
