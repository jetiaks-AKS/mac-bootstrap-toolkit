# Mac Bootstrap Toolkit Commands

---

# Toolkit

## Проверка системы

Проверить текущее состояние системы без внесения изменений.

```bash
./bootstrap.sh --check
```

---

## Проверка системы (Verbose)

Показать подробную информацию о каждом модуле.

```bash
./bootstrap.sh --check --verbose
```

---

## Bootstrap

Полностью подготовить новый Mac.

```bash
./bootstrap.sh --bootstrap
```

Выполняет:

- настройку Git;
- проверку SSH;
- настройку Terminal;
- установку Homebrew Packages;
- установку Homebrew Casks;
- автоматическое восстановление отсутствующих Homebrew Casks;
- установку приложений App Store;
- установку расширений VS Code;
- применение настроек VS Code;
- настройку Finder;
- настройку Dock;
- настройку Keyboard;
- настройку Trackpad;
- настройку Screenshots.

После завершения выводится итоговый Summary.

---

## Bootstrap (Verbose)

Полностью подготовить новый Mac с подробным выводом.

```bash
./bootstrap.sh --bootstrap --verbose
```

Показывает:

- проверку каждого модуля;
- уже установленные пакеты Homebrew;
- уже установленные Homebrew Casks;
- уже установленные приложения App Store;
- уже установленные расширения VS Code;
- подробную информацию обо всех выполняемых действиях.

---

## Версия Toolkit

```bash
./bootstrap.sh --version
```

---

## Справка

```bash
./bootstrap.sh --help
```

---

# Git

## Проверить состояние репозитория

```bash
git status
```

## Последние коммиты

```bash
git log --oneline -10
```

## Отправить изменения

```bash
git push
```

## Получить изменения

```bash
git pull
```

---

# Экспорт настроек macOS

Экспортировать текущие настройки macOS.

```bash
./scripts/export-macos-settings.sh
```

Результат сохраняется в:

```text
exports/macos/
```

---

# Анализ настроек macOS

Проверить экспортированные настройки.

```bash
./scripts/analyze-macos-settings.sh
```
