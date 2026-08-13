# Быстрый старт

[English](QUICKSTART.md) | Русский

## 1. Клонировать репозиторий

```bash
git clone git@github.com:jetiaks-AKS/mac-bootstrap-toolkit.git
```

## 2. Перейти в каталог проекта

```bash
cd mac-bootstrap-toolkit
```

---

## 3. Проверить систему

Перед выполнением Bootstrap рекомендуется проверить текущее состояние системы.

Стандартный режим:

```bash
./bootstrap.sh --check
```

Для получения подробной информации используйте:

```bash
./bootstrap.sh --check --verbose
```

Toolkit проверит:

* Internet connection;
* Xcode Command Line Tools;
* macOS version;
* administrator privileges;
* Homebrew;
* Git;
* SSH;
* Terminal.

В стандартном режиме вывод остаётся компактным.

Verbose Mode дополнительно показывает диагностическую информацию.

---

## 4. Выполнить Discovery

Перед переносом рабочего окружения рекомендуется выполнить анализ текущей системы.

Стандартный режим:

```bash
./bootstrap.sh --discover
```

Подробный режим:

```bash
./bootstrap.sh --discover --verbose
```

Discovery автоматически соберёт информацию о:

* Homebrew Packages;
* Homebrew Casks;
* App Store applications;
* Git configuration;
* VS Code Extensions;
* VS Code Settings;
* macOS Settings;
* Workspace;
* структуре каталогов;
* Git-репозиториях;
* repository metadata;
* VS Code Workspaces.

Результаты сохраняются локально в каталоге:

```text
config/generated/
```

`config/generated/` содержит machine-specific данные,
полученные в результате Discovery, и исключён из Git.

Полученные конфигурации используются Bootstrap Engine
для последующего восстановления системы.

---

## 5. Выполнить Bootstrap

Bootstrap использует конфигурацию, ранее подготовленную
Discovery Engine, и автоматически воспроизводит рабочее окружение.

Стандартный режим:

```bash
./bootstrap.sh --bootstrap
```

Подробный режим:

```bash
./bootstrap.sh --bootstrap --verbose
```

Toolkit автоматически:

* проверит и при необходимости установит Homebrew;
* проверит Git;
* проверит SSH;
* проверит Terminal;
* восстановит Workspace;
* проверит Git repositories;
* проверит Remote URL;
* проверит текущие Git branches;
* восстановит необходимые Homebrew Packages;
* восстановит необходимые Homebrew Casks;
* восстановит отсутствующие Homebrew Casks при необходимости;
* установит приложения App Store;
* установит расширения VS Code;
* применит настройки VS Code;
* создаст резервную копию текущих настроек VS Code;
* настроит Finder;
* настроит Dock;
* настроит Keyboard;
* настроит Trackpad;
* настроит Screenshots.

Bootstrap является идемпотентным.

Если компонент уже находится в требуемом состоянии,
изменения не выполняются.

После завершения Toolkit покажет итоговый Summary:

```text
Modules Checked
Installed
Skipped
Warnings
Errors
Duration
```

---

## Что пока недоступно

Dry-run, Blueprint, Verification, Restore и AI Assistant запланированы,
но не входят в функциональность версии 2.0.1. В частности, опция
`--dry-run` текущим CLI не поддерживается.

---

## Дополнительные команды

### Проверка системы

```bash
./bootstrap.sh --check
```

### Проверка системы (Verbose)

```bash
./bootstrap.sh --check --verbose
```

### Discovery

```bash
./bootstrap.sh --discover
```

### Discovery (Verbose)

```bash
./bootstrap.sh --discover --verbose
```

### Bootstrap

```bash
./bootstrap.sh --bootstrap
```

### Bootstrap (Verbose)

```bash
./bootstrap.sh --bootstrap --verbose
```

### Версия Toolkit

```bash
./bootstrap.sh --version
```

### Справка

```bash
./bootstrap.sh --help
```

---

## Логи

Каждый запуск Toolkit создаёт исторический лог.

Последний запуск доступен здесь:

```text
logs/latest.log
```

История запусков хранится в:

```text
logs/history/
```

Типы исторических логов:

```text
check-YYYY-MM-DD_HH-MM-SS.log
bootstrap-YYYY-MM-DD_HH-MM-SS.log
discover-YYYY-MM-DD_HH-MM-SS.log
```

Быстро посмотреть последний лог:

```bash
cat logs/latest.log
```

Посмотреть последние записи:

```bash
tail -30 logs/latest.log
```

Посмотреть историю запусков:

```bash
ls -lt logs/history/
```

Логи являются локальными рабочими файлами и не попадают
в Git.

---

## Требования

* macOS 15 или новее
* Xcode Command Line Tools
* Подключение к Интернету
* Учётная запись администратора
* Git
* Homebrew устанавливается Toolkit автоматически,
  если он отсутствует
