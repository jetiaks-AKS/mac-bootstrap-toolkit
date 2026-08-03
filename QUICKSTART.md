# Quick Start

## 1. Клонировать репозиторий

```bash
git clone git@github.com:jetiaks-AKS/mac-bootstrap-toolkit.git
```

## 2. Перейти в каталог проекта

```bash
cd mac-bootstrap-toolkit
```

## 3. Проверить систему

Перед выполнением Bootstrap рекомендуется проверить текущее состояние системы.

```bash
./bootstrap.sh --check
```

Toolkit проверит:

- Homebrew
- Git
- SSH
- Terminal
- Finder
- Dock
- Keyboard
- Trackpad
- Screenshots

## 4. Выполнить Bootstrap

Если всё готово:

```bash
./bootstrap.sh --bootstrap
```

Toolkit автоматически:

- настроит Git;
- установит Homebrew Packages;
- установит Homebrew Casks;
- установит приложения App Store;
- установит расширения VS Code;
- применит настройки VS Code;
- настроит Finder;
- настроит Dock;
- настроит Keyboard;
- настроит Trackpad;
- настроит Screenshots.

## Дополнительные команды

Показать справку:

```bash
./bootstrap.sh --help
```

Показать версию Toolkit:

```bash
./bootstrap.sh --version
```

## Требования

- macOS Tahoe 26 или новее
- Подключение к Интернету
- Учётная запись администратора
