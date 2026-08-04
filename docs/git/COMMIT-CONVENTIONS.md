# Commit Conventions

Правила оформления сообщений коммитов в проекте **Mac Bootstrap Toolkit**.

---

# Общий формат

```
type: краткое описание
```

Примеры:

```
feat: add self-healing for Homebrew Casks

fix: correct summary statistics

docs: update Quick Start guide

refactor: simplify Git configuration module
```

---

# Типы коммитов

## feat

Новая функциональность.

Пример:

```text
feat: add quiet mode for Homebrew
```

---

## fix

Исправление ошибок.

Пример:

```text
fix: detect missing Homebrew Casks
```

---

## refactor

Изменение внутренней архитектуры без изменения поведения.

Пример:

```text
refactor: simplify VS Code settings module
```

---

## docs

Изменения документации.

Пример:

```text
docs: update README
```

---

## style

Изменения форматирования без изменения логики.

Пример:

```text
style: reformat shell scripts
```

---

## chore

Служебные изменения.

Пример:

```text
chore: start development of version 1.2.0
```

---

## release

Подготовка стабильного релиза.

Пример:

```text
release: version 1.1.0
```

---

# Правила

✅ Один коммит — одна логическая задача.

✅ Сообщение начинается с маленькой буквы после `type:`.

✅ Используется английский язык.

✅ Описание должно быть коротким и понятным.

---

# Хорошие примеры

```text
feat: add bootstrap summary

feat: support App Store applications

fix: restore missing Homebrew Casks

fix: improve Git configuration check

docs: update roadmap

docs: add Git documentation

refactor: simplify module loading

release: version 1.1.0

chore: start development of version 1.2.0
```

---

# Не рекомендуется

❌

```text
update

changes

fix

new version

bug fixes

misc
```

Такие сообщения не позволяют понять историю проекта.

---

# Принцип проекта

История Git должна читаться как журнал разработки.

Каждый коммит должен отвечать на вопрос:

> Что изменилось?
