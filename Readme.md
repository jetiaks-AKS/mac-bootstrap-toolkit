# Mac Bootstrap Toolkit

Автоматическая подготовка нового Mac к работе за несколько минут.

Текущая версия: **1.1.0 (Stable)**.

---

## Возможности

- автоматическая установка Homebrew Packages;
- автоматическая установка Homebrew Casks;
- установка приложений App Store;
- установка расширений VS Code;
- применение настроек VS Code;
- настройка macOS;
- Quiet Mode по умолчанию;
- режим Verbose (`--verbose`);
- автоматическое восстановление Homebrew Casks (Self-Healing);
- безопасный повторный запуск (Idempotent);
- итоговый Summary с результатами выполнения.

---

## Принципы

- модульная архитектура;
- идемпотентность (Idempotent);
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

`.
├── assets/
├── config/
├── docs/
├── modules/
├── scripts/
└── tests/

---

## План развития

## Реализовано

### Core

- [x] Homebrew
- [x] Git
- [x] SSH
- [x] Terminal

### Applications

- [x] Homebrew Packages
- [x] Homebrew Casks
- [x] App Store

### VS Code

- [x] Extensions
- [x] Settings

### macOS

- [x] Finder
- [x] Dock
- [x] Keyboard
- [x] Trackpad
- [x] Screenshots

### CLI

- [x] `--check`
- [x] `--bootstrap`
- [x] `--help`
- [x] `--version`

| Параметр     | Значение      |
| ------------ | ------------- |
| Статус       | ✅ Стабильный  |
| Версия        | **1.1.0**     |
| Платформа    | macOS         |
| Язык         | Bash          |
| Архитектура  | Модульная     |
| Конфигурация | Идемпотентная |

---

✅ Версия 1.1.0 является текущим стабильным релизом Mac Bootstrap Toolkit.

Следующий этап разработки начинается с версии 1.2.0-dev.
