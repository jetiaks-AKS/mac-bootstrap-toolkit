# Mac Bootstrap Toolkit Commands

---

# Toolkit

## Проверка системы

Проверить текущее состояние системы без внесения изменений.

```bash
./bootstrap.sh --check
```

---

## Bootstrap

Полностью подготовить новый Mac.

```bash
./bootstrap.sh --bootstrap
```

Выполняет:

- настройку Git;
- установку Homebrew Packages;
- установку Homebrew Casks;
- установку App Store приложений;
- установку расширений VS Code;
- применение настроек VS Code;
- настройку Finder;
- настройку Dock;
- настройку Keyboard;
- настройку Trackpad;
- настройку Screenshots.

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

Проверить состояние репозитория.

```bash
git status
```

Последние коммиты.

```bash
git log --oneline -10
```

Отправить изменения.

```bash
git push
```

Получить изменения.

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
