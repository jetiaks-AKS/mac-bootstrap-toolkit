# Config Engine

## Назначение

Config Engine предоставляет единый API для чтения автоматически сгенерированных конфигурационных файлов Mac Bootstrap Toolkit.

Модуль используется всеми компонентами Toolkit и полностью скрывает реализацию чтения конфигурационных файлов.

---

## Ответственность

Config Engine отвечает за:

- чтение секций конфигурационного файла;
- получение значений параметров;
- предоставление единого интерфейса для работы с конфигурацией.

---

## Поддерживаемый формат

```ini
[section]

KEY="value"
KEY="value"
KEY="value"
```

---

## API

### config_sections()

Возвращает список всех секций конфигурационного файла.

Пример:

```bash
config_sections repositories.conf
```

Результат:

```text
mac-bootstrap-toolkit
Infrastructure
```

---

### config_get()

Возвращает значение указанного ключа из выбранной секции.

Пример:

```bash
config_get repositories.conf mac-bootstrap-toolkit PATH
```

Результат:

```text
/Users/username/Projects/mac-bootstrap-toolkit
```

---

## Принципы

Config Engine построен на следующих принципах:

- Stateless (не хранит внутреннее состояние);
- простое API;
- одна функция — одна задача;
- не зависит от Git, Workspace, VS Code или macOS;
- работает только с конфигурационными файлами Toolkit.

---

## Используется

- Bootstrap Engine
- Discovery Engine
- Verification Engine (планируется)
- Restore Engine (планируется)
