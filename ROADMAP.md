# ROADMAP

План развития проекта **Mac Bootstrap Toolkit**.

---

## Long-term Vision

Mac Bootstrap Toolkit развивается как единый набор инструментов для анализа, подготовки и восстановления рабочего пространства macOS.

Проект состоит из четырех основных компонентов:

• Bootstrap Engine
• Discovery Engine
• Blueprint Manager
• Restore Engine

Каждый компонент развивается независимо, но использует общую модульную архитектуру Toolkit.

# ✅ Version 1.0.0 (Stable)

## Core

- [x] Модульная архитектура Toolkit.
- [x] Система логирования (`INFO`, `OK`, `WARN`, `ERROR`).
- [x] Проверка системы (`--check`).
- [x] Полная настройка (`--bootstrap`).
- [x] Команда `--help`.
- [x] Команда `--version`.

## Preflight

- [x] Проверка подключения к Интернету.
- [x] Проверка Xcode Command Line Tools.
- [x] Проверка версии macOS.
- [x] Проверка прав администратора.

## Homebrew

- [x] Проверка Homebrew.
- [x] Установка Homebrew.
- [x] Установка Homebrew Packages.
- [x] Установка Homebrew Casks.

## Git

- [x] Проверка установки Git.
- [x] Проверка конфигурации Git.
- [x] Автоматическая настройка Git.

## SSH

- [x] Проверка SSH.

## Terminal

- [x] Проверка Terminal.

## App Store

- [x] Установка приложений через `mas`.
- [x] Проверка уже установленных приложений.

## VS Code

- [x] Установка расширений.
- [x] Применение `settings.json`.
- [x] Резервное копирование текущих настроек.
- [x] Проверка актуальности настроек.

## macOS

- [x] Настройка Finder.
- [x] Настройка Dock.
- [x] Настройка Keyboard.
- [x] Настройка Trackpad.
- [x] Настройка Screenshots.

---

# ✅ Version 1.1.0 (Stable)

## Интерфейс

- [x] Компактный вывод Toolkit.
- [x] Режим `--verbose`.
- [x] Quiet Mode по умолчанию.
- [x] Compact / Verbose режимы.
- [x] Унифицирован вывод всех модулей.
- [x] Итоговый Summary.
- [x] Подсчёт установленных и пропущенных компонентов.
- [x] Отображение времени выполнения Bootstrap.

## Toolkit

- [x] Verify After Apply.
- [x] Self-Healing Homebrew Casks.
- [x] Унифицированная система проверки модулей.
- [x] Единый принцип `MODULE_CHANGED`.

## Homebrew

- [x] Автоматическое восстановление повреждённых Casks.
- [x] Проверка фактического состояния приложений.

## VS Code

- [x] Автоматическое резервное копирование `settings.json`.
- [x] Идемпотентное применение настроек.

---

# 🚀 Version 1.2.0

## Bootstrap Engine

### Toolkit

- [ ] Логирование в файл.
- [ ] Режим `--dry-run`.
- [ ] Bootstrap Report.
- [ ] Backup / Restore конфигурации.
- [ ] Таймер выполнения каждого модуля.
- [ ] Индикатор выполнения длительных операций.

### Git

- [ ] Показывать изменения конфигурации перед применением.

### SSH

- [ ] Автоматическое создание SSH-ключа.
- [ ] Добавление ключа в `ssh-agent`.
- [ ] Проверка подключения к GitHub.

### VS Code

- [ ] Импорт `keybindings.json`.
- [ ] Импорт пользовательских `snippets`.

### macOS

- [ ] Настройка Menu Bar.
- [ ] Настройка Power Management.
- [ ] Настройка Login Items.

### Infrastructure

- [ ] Создание структуры папки Infrastructure.
- [ ] Импорт VS Code Workspace.
- [ ] Клонирование Git-репозиториев.
- [ ] Создание стандартных каталогов проекта.

### Configuration Profiles

- [ ] Personal
- [ ] Work
- [ ] Minimal

---

## Discovery Engine

### Foundation

- [x] Режим `--discover`
- [x] Discovery Controller

### Homebrew

- [x] Export Formulae
- [ ] Export Casks

### Development

- [ ] Git
- [ ] SSH
- [ ] Terminal
- [ ] Shell / Aliases

### VS Code

- [ ] Extensions
- [ ] Settings
- [ ] User Snippets

### macOS

- [ ] Finder
- [ ] Dock
- [ ] Keyboard
- [ ] Trackpad
- [ ] Mission Control
- [ ] Menu Bar

### Workspace

- [ ] Applications
- [ ] User folders
- [ ] Documents
- [ ] Projects
- [ ] Infrastructure
- [ ] Optional Workspace Archive

### Reports

- [ ] Discovery Report

# 🌟 Version 2.0

## Blueprint Manager

Цель:
Создание переносимого Blueprint рабочего пространства.

### Blueprint

- [ ] Просмотр результатов Discovery
- [ ] Выбор компонентов пользователем
- [ ] Создание Blueprint
- [ ] Manifest.json
- [ ] Проверка Blueprint

---

## Restore Engine

Цель:
Восстановление рабочего пространства из Blueprint.

### Restore

- [ ] Загрузка Blueprint
- [ ] Анализ содержимого
- [ ] Выбор компонентов пользователем
- [ ] Восстановление приложений
- [ ] Восстановление настроек
- [ ] Восстановление Workspace

---

## Toolkit

- [ ] Автоматическое тестирование модулей.
- [ ] Автоматическая проверка после изменений.
- [ ] Поддержка новых версий macOS.
- [ ] Поддержка плагинов.
- [ ] Интеграция с CI/CD.
- [ ] Автоматическая сборка релизов.
