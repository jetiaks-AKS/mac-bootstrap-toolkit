# Mac Bootstrap Toolkit

[English](README.md) | Русский

Модульный Bash Toolkit для воспроизводимой подготовки и восстановления
рабочего окружения macOS.

**Текущая версия: 3.0.0 Stable**

---

## Назначение

Mac Bootstrap Toolkit позволяет:

- анализировать поддерживаемые компоненты существующего окружения macOS;
- автоматически формировать машинно-зависимую конфигурацию;
- при необходимости выбирать, какие обнаруженные компоненты восстанавливать;
- выполнять Bootstrap выбранного окружения на другом Mac;
- проверять поддерживаемое состояние до и после применения изменений.

Главная идея проекта — воспроизводить **рабочее пространство пользователя**,
а не копировать всю операционную систему.

---

## Workflow

```text
Existing Mac
     ↓
 Discovery
     ↓
Generated Configuration
     ↓
 Blueprint
     ↓
 Bootstrap
     ↓
Ready-to-Work Mac
```

Discovery сохраняет обнаруженное состояние в `config/generated/`.

Blueprint — необязательный локальный слой выбора, определяющий, какие
обнаруженные компоненты должен обрабатывать Bootstrap. Без Blueprint
обрабатывается полный поддерживаемый scope.

---

## Возможности

### Discovery

- Homebrew Packages и Casks
- приложения App Store
- Git Configuration
- VS Code Extensions и Settings
- настройки macOS
- структура Workspace и Git Repositories

### Blueprint

- интерактивный выбор компонентов;
- item-level и category-level фильтрация;
- изменение существующего выбора;
- безопасная отмена без изменения сохранённого Blueprint.

### Bootstrap

- Applications
- Git Configuration
- VS Code Extensions и Settings
- настройки macOS
- Workspace Folders
- восстановление Git Repositories и Branches

Операции Toolkit проектируются идемпотентными и проверяют поддерживаемое
состояние до и после изменений там, где это применимо.

---

## Быстрый старт

Проверить систему:

```bash
./bootstrap.sh --check
```

Проанализировать текущее окружение:

```bash
./bootstrap.sh --discover
```

При необходимости создать или изменить Blueprint:

```bash
./bootstrap.sh --blueprint
```

Восстановить окружение:

```bash
./bootstrap.sh --bootstrap
```

Для подробного вывода Check, Discovery и Bootstrap поддерживают `--verbose`.

Полный сценарий описан в
[Quick Start](docs/getting-started/QUICKSTART.md).

---

## Документация

- [Quick Start](docs/getting-started/QUICKSTART.md)
- [Architecture](docs/toolkit/ARCHITECTURE.md)
- [Configuration](docs/toolkit/CONFIGURATION.md)
- [CLI](docs/toolkit/CLI.md)
- [Roadmap](ROADMAP.md)
- [Changelog](CHANGELOG.md)

---

## Статус проекта

**3.0.0 Stable**

Текущая архитектура:

```text
Discovery → Generated Configuration → Blueprint → Bootstrap
```

Dry-run / Preview и глобальный Verification остаются будущими возможностями.

Дальнейшее развитие описано в [ROADMAP.md](ROADMAP.md).

---

## Поддержка

Mac Bootstrap Toolkit распространяется бесплатно и с открытым исходным кодом.

Если проект оказался полезен, его дальнейшую разработку можно поддержать
добровольным пожертвованием через
[Boosty](https://boosty.to/jetiaks/donate).

---

## Лицензия

Mac Bootstrap Toolkit распространяется по лицензии [MIT](LICENSE).
