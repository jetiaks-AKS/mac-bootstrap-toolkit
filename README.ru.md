# Mac Bootstrap Toolkit

[English](README.md) | Русский

Модульный Bash Toolkit для воспроизводимой подготовки и восстановления
рабочего окружения macOS.

**Текущая версия: 3.1.0 Stable**

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
- немедленная отмена через `q` / `Q` в любом prompt, включая Edit, без
  изменения сохранённого Blueprint.

### Bootstrap

- Applications
- Git Configuration
- VS Code Extensions и Settings
- настройки macOS
- Workspace Folders
- восстановление Git Repositories и Branches

Операции Toolkit проектируются идемпотентными и проверяют поддерживаемое
состояние до и после изменений там, где это применимо.

### Preview

- неизменяющая проверка `--dry-run` для Applications, Git configuration,
  VS Code settings, Workspace и macOS;
- Blueprint-aware planned actions на основе той же validation и inspection
  логики, которую использует Bootstrap;
- Summary по проверенным модулям, warnings, errors и duration.

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

Предварительно просмотреть выбранные изменения без мутации target state:

```bash
./bootstrap.sh --dry-run
```

Запустить интерактивный сценарий:

```bash
./bootstrap.sh --workflow
```

Первый запуск по-прежнему использует каноническую точку входа:

```bash
./bootstrap.sh --workflow
```

Когда Workflow доходит до Bootstrap или напрямую выполняется
`./bootstrap.sh --bootstrap`, Bootstrap автоматически устанавливает и проверяет
короткий launcher. Repository entrypoint остаётся каноническим. После установки
launcher работает из любого текущего каталога:

```bash
bs workflow
bs discover
bs blueprint
bs preview
bs bootstrap
bs check
```

Discovery, Blueprint, Preview и Workflow, завершившийся после zero-change
Preview, не устанавливают `bs`. Для ручной установки или восстановления
используйте `./scripts/install-bs.sh`. Installer использует текущий Homebrew
prefix, если он доступен, и не заменяет постороннюю команду или файл `bs`.
После перемещения репозитория PATH symlink становится недействительным; удалите
старую ссылку и повторно запустите installer из нового расположения.

Используйте существующую Generated Configuration или обновите её, сохраните
Blueprint и просмотрите обязательный Preview. Если Preview находит planned
changes, Workflow запрашивает явное подтверждение Bootstrap (по умолчанию —
Нет). Отсутствующий или некорректный обязательный ввод требует Discovery; отказ
от Discovery или отмена Blueprint завершает сценарий без ошибки. Предупреждения
Preview допускают подтверждение при наличии планов, ошибки блокируют Bootstrap.
Если Preview не находит изменений, Workflow завершается без предложения
Bootstrap, сохраняя статус предупреждений.
Поддерживается `--verbose`. Каждый этап сохраняет свои логи и Summary.
Discovery сохраняет обычный preflight и запись локальной конфигурации.


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

**3.1.0 Stable**

Текущая архитектура:

```text
Discovery → Generated Configuration → Blueprint → Bootstrap
```

Dry-run / Preview входит в релиз 3.1.0. Глобальный Verification остаётся
будущей возможностью.

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
