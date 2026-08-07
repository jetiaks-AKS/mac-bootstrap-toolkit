# Архитектура Mac Bootstrap Toolkit

## Назначение

Mac Bootstrap Toolkit построен по модульной архитектуре.

Проект разделён на независимые компоненты, каждый из которых отвечает только за свою область ответственности.

Основной принцип архитектуры — максимальное разделение логики между этапами анализа системы (Discovery), генерации конфигурации (Generated Config) и применения настроек (Bootstrap).

---

# Общая схема

```
                    Mac Bootstrap Toolkit
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
        ▼                    ▼                    ▼
   Discovery Engine     Bootstrap Engine     Documentation
        │                    │
        │                    ▼
        │             Применение конфигурации
        │
        ▼
 Генерация конфигурации
        │
        ▼
 config/generated/
        │
        ▼
      Config Engine
        │
        ▼
     Core Services
```

---

# Core

Core содержит общие сервисы, используемые всеми модулями Toolkit.

На текущий момент реализованы:

- Common
- Logger
- Preflight
- Homebrew
- Git
- SSH
- Terminal
- Config Engine

Core не содержит бизнес-логики и не зависит от Discovery или Bootstrap.

---

# Discovery Engine

Discovery Engine анализирует текущую систему пользователя.

Он автоматически собирает информацию о:

- Homebrew Packages
- Homebrew Casks
- App Store
- Git
- VS Code
- Workspace
- macOS Settings

Результатом работы Discovery являются конфигурационные файлы в каталоге:

```

config/generated/

```

Discovery ничего не изменяет в системе пользователя.

---

# Generated Configuration

Все результаты Discovery сохраняются в виде обычных текстовых конфигурационных файлов.

Каждый файл описывает одну подсистему Toolkit.

Например:

```

config/generated/

workspace/
repositories.conf
folders.conf

brew/
packages.conf
casks.conf

vscode/
extensions.conf

```

Bootstrap никогда не анализирует систему самостоятельно.

Он использует только автоматически сгенерированную конфигурацию.

---

# Config Engine

Config Engine предоставляет единый API для чтения конфигурационных файлов.

На текущий момент реализованы функции:

- config_sections()
- config_get()

Все Bootstrap-модули используют Config Engine вместо собственного парсинга файлов.

---

# Bootstrap Engine

Bootstrap Engine отвечает за применение конфигурации на новом Mac.

На текущий момент поддерживаются:

- Workspace
- Homebrew Packages
- Homebrew Casks
- App Store
- VS Code Extensions
- VS Code Settings
- macOS Settings

Bootstrap построен по принципу идемпотентности и безопасен для повторного запуска.

---

# Документация

Документация разделена по темам.

Каждый документ описывает только одну часть Toolkit.

Это позволяет избежать дублирования информации и упрощает сопровождение проекта.

---

# Принципы архитектуры

При разработке Toolkit используются следующие принципы:

- модульная архитектура;
- одна ответственность на модуль;
- идемпотентность;
- Verify After Apply;
- Quiet by Default;
- Verbose When Needed;
- Stateless Core;
- повторное использование компонентов;
- минимальное количество ручных действий;
- единый стиль документации.

---

# Текущее состояние

На данный момент полностью реализованы:

- Core
- Discovery Engine
- Bootstrap Engine
- Config Engine
- Generated Configuration

Следующим этапом развития станет реализация Restore Engine и Verification Engine.
