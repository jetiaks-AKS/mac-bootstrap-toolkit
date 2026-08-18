# Bootstrap Workspace

## Назначение

Модуль отвечает за восстановление поддерживаемой структуры рабочего
пространства пользователя.

Источником данных являются generated-конфигурации, сформированные
Workspace Discovery.

---

## Используемые конфигурации

Текущий Workspace Bootstrap использует:

- `folders.conf`
- `repositories.conf`

Если эти файлы требуются текущим выбором Blueprint, Bootstrap проверяет
их наличие, читаемость и структуру до начала любых Workspace-изменений.

Все требуемые входные конфигурации проходят валидацию до создания первого
каталога, клонирования репозитория или восстановления ветки.

Отсутствующий, нечитаемый или malformed обязательный input завершает
Workspace со статусом `2` без частичного применения состояния.

Без Blueprint сохраняется legacy all-inclusive обработка.

`inventory.conf` и `vscode-workspaces.conf` не являются входами текущего
Workspace Bootstrap.

---

## Основные задачи

### Folders

Создание выбранной структуры каталогов пользователя.

При наличии Blueprint обычными кандидатами являются записи `folders.conf`
с классификацией `workspace`. Каталоги `user` и `system` остаются частью
наблюдаемой Generated Configuration, но не предлагаются как обычные
Workspace Folder choices.

Без Blueprint сохраняется legacy all-inclusive поведение.

### Repositories

Клонирование отсутствующих Git-репозиториев и проверка существующих.

Для существующего репозитория Bootstrap проверяет соответствие remote
ожидаемой конфигурации.

Если репозиторий не удаётся клонировать или проверить, remote не совпадает
с конфигурацией либо требуемую ветку нельзя безопасно восстановить,
Bootstrap сохраняет существующие данные, продолжает обработку остальных
репозиториев и завершает Workspace с предупреждением.

### Branches

Восстановление рабочей Git-ветки выполняется только тогда, когда это можно
сделать безопасно.

Bootstrap не переключает ветку при наличии незакоммиченных изменений и
не изменяет существующий Git remote для исправления несовпадения.

---

## VS Code Workspaces

Workspace Discovery обнаруживает VS Code Workspaces и формирует
`vscode-workspaces.conf`.

Текущий Workspace Bootstrap этот файл не потребляет. Восстановление
`.code-workspace` и VS Code Projects пока не реализовано и отключено
от production-оркестрации.

---

## Принцип работы

```text
Discovery
    ↓
config/generated/workspace/
    ↓
Blueprint
    ↓
Input Validation
    ↓
Bootstrap Workspace
    ↓
Folders + Git Repositories
