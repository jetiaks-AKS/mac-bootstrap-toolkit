# Bootstrap Modules

## Назначение

Данный раздел содержит модули, отвечающие за восстановление рабочего
окружения на новом Mac.

Bootstrap использует Generated Configuration, сформированную Discovery,
учитывает выбор Blueprint и применяет поддерживаемое целевое состояние
к системе.

---

## Основная задача

Воссоздать поддерживаемую рабочую среду пользователя автоматически,
безопасно и идемпотентно.

---

## Принцип работы

```text
Generated Configuration
        ↓
Blueprint selection / validation
        ↓
Bootstrap
        ↓
Check → Apply → Verify
