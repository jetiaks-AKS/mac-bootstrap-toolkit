# Git Cheat Sheet

Наиболее часто используемые команды Git при разработке **Mac Bootstrap Toolkit**.

---

# Проверка состояния

## Проверить состояние репозитория

```bash
git status
```

Показывает:

- текущую ветку;
- изменённые файлы;
- новые файлы;
- файлы, подготовленные к коммиту.

---

## Посмотреть текущую ветку

```bash
git branch
```

Текущая ветка отмечается символом `*`.

---

## История коммитов

```bash
git log --oneline --graph --decorate --all
```

Позволяет увидеть историю проекта, ветки, merge-коммиты и теги.

---

# Работа с изменениями

## Добавить все изменения

```bash
git add .
```

---

## Добавить один файл

```bash
git add README.md
```

---

## Посмотреть изменения

```bash
git diff
```

---

## Посмотреть подготовленные изменения

```bash
git diff --cached
```

---

# Коммиты

## Создать коммит

```bash
git commit -m "feat: add new module"
```

---

## Изменить сообщение последнего коммита

```bash
git commit --amend
```

---

## Последний коммит

```bash
git log -1
```

---

# Ветки

## Переключиться на develop

```bash
git checkout develop
```

или

```bash
git switch develop
```

---

## Переключиться на main

```bash
git checkout main
```

---

## Создать новую ветку

```bash
git checkout -b feature/new-module
```

---

# Merge

## Слить develop в main

```bash
git checkout main

git merge --no-ff develop
```

---

# Теги

## Посмотреть теги

```bash
git tag
```

---

## Создать тег

```bash
git tag -a v1.1.0 -m "Mac Bootstrap Toolkit 1.1.0"
```

---

## Удалить тег

```bash
git tag -d v1.1.0
```

---

# GitHub

## Отправить develop

```bash
git push origin develop
```

---

## Отправить main

```bash
git push origin main
```

---

## Отправить все теги

```bash
git push origin --tags
```

---

## Получить изменения

```bash
git pull
```

---

# Полезные команды

## Посмотреть удалённые репозитории

```bash
git remote -v
```

---

## Посмотреть текущий commit

```bash
git rev-parse HEAD
```

---

## Посмотреть последние 10 коммитов

```bash
git log --oneline -10
```

---

## Посмотреть все ветки

```bash
git branch -a
```

---

# Типичный цикл разработки

```text
checkout develop

↓

git pull

↓

изменения

↓

git status

↓

git add .

↓

git commit

↓

git push origin develop
```

---

# Выпуск новой версии

```text
Обновить документацию

↓

Обновить версию Toolkit

↓

Commit

↓

Merge develop → main

↓

Создать Tag

↓

Push

↓

Вернуться в develop

↓

Начать новую dev-версию
```
