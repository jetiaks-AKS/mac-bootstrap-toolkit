# Quick Start

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

```bash
./bootstrap.sh --check
```

Для получения подробной информации используйте:

```bash
./bootstrap.sh --check --verbose
```

Toolkit проверит:

- Homebrew
- Git
- SSH
- Terminal
- Homebrew Packages
- Homebrew Casks
- App Store Applications
- VS Code Extensions
- VS Code Settings
- macOS Settings

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

- Homebrew;
- Git;
- VS Code;
- настройках macOS;
- Workspace;
- структуре каталогов;
- Git-репозиториях.

Результаты сохраняются в каталоге:

```text
config/generated/
```

Полученные конфигурации используются Bootstrap Engine для последующего восстановления системы.

---

## 5. Выполнить Bootstrap

Bootstrap использует конфигурацию, ранее подготовленную Discovery Engine, и автоматически воспроизводит рабочее окружение.

Стандартный режим:

```bash
./bootstrap.sh --bootstrap
```

Подробный режим:

```bash
./bootstrap.sh --bootstrap --verbose
```

Toolkit автоматически:

- установит и настроит Homebrew;
- настроит Git;
- проверит SSH;
- настроит Terminal;
- установит Homebrew Packages;
- установит Homebrew Casks;
- восстановит отсутствующие Homebrew Casks при необходимости;
- установит приложения App Store;
- установит расширения VS Code;
- применит настройки VS Code;
- создаст резервную копию текущих настроек VS Code;
- настроит Finder;
- настроит Dock;
- настроит Keyboard;
- настроит Trackpad;
- настроит Screenshots.

После завершения Toolkit покажет итоговый Summary с количеством проверенных, изменённых и пропущенных модулей.

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

## Требования

- macOS Tahoe 26 или новее
- Xcode Command Line Tools
- Подключение к Интернету
- Учётная запись администратора
