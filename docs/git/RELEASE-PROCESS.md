# Release Process

Порядок подготовки и выпуска новой стабильной версии **Mac Bootstrap Toolkit**.

---

# 1. Завершить разработку

Убедиться, что:

- все задачи версии выполнены;
- все тесты успешно пройдены;
- отсутствуют известные ошибки;
- Toolkit работает корректно.

---

# 2. Обновить документацию

При необходимости обновить:

- README.md
- CHANGELOG.md
- ROADMAP.md
- QUICKSTART.md
- COMMANDS.md

При необходимости обновить документацию в каталоге `docs/`.

---

# 3. Обновить версию Toolkit

Изменить:

```text
config/toolkit.conf
```

Например:

```text
TOOLKIT_VERSION="1.2.0"
```

---

# 4. Финальное тестирование

Выполнить:

```bash
./bootstrap.sh --check

./bootstrap.sh --bootstrap

./bootstrap.sh --bootstrap --verbose
```

Проверить:

- Summary;
- вывод CLI;
- отсутствие ошибок;
- идемпотентность повторного запуска.

---

# 5. Проверить Git

```bash
git status

git diff --stat
```

При необходимости:

```bash
git diff
```

---

# 6. Коммит релиза

Добавить изменения:

```bash
git add .
```

Создать коммит:

```bash
git commit -m "release: version 1.2.0"
```

---

# 7. Merge в main

Переключиться:

```bash
git checkout main
```

Объединить:

```bash
git merge --no-ff develop
```

---

# 8. Создать Git Tag

```bash
git tag -a v1.2.0 -m "Mac Bootstrap Toolkit 1.2.0"
```

Проверить:

```bash
git tag
```

---

# 9. Отправить на GitHub

```bash
git push origin main

git push origin --tags
```

---

# 10. Вернуться в develop

```bash
git checkout develop
```

---

# 11. Начать следующую версию

Изменить:

```text
config/toolkit.conf
```

Например:

```text
TOOLKIT_VERSION="1.3.0-dev"
```

Добавить изменения:

```bash
git add .
```

Создать коммит:

```bash
git commit -m "chore: start development of version 1.3.0"
```

Отправить:

```bash
git push origin develop
```

---

# Контрольный список

Перед выпуском убедиться, что выполнены все пункты.

- [ ] Разработка завершена.
- [ ] Документация обновлена.
- [ ] Версия Toolkit обновлена.
- [ ] Финальное тестирование выполнено.
- [ ] Проверен Git Status.
- [ ] Создан релизный коммит.
- [ ] Выполнен Merge в main.
- [ ] Создан Git Tag.
- [ ] Изменения отправлены на GitHub.
- [ ] Начата следующая dev-версия.

---

# Используемые ветки

```
develop
```

Используется для ежедневной разработки.

```
main
```

Содержит только стабильные версии проекта.

---

# Принцип

Каждый релиз должен быть полностью воспроизводим.

Любой участник проекта должен иметь возможность открыть этот документ и выполнить выпуск новой версии, не обращаясь к дополнительным инструкциям.
