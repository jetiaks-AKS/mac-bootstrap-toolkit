# Vision Mac Bootstrap Toolkit

## Главная цель проекта

Mac Bootstrap Toolkit создаётся для того, чтобы полностью автоматизировать перенос рабочего окружения на новый Mac.

Конечная цель проекта — возможность подготовить новый компьютер к работе одной командой без ручной настройки системы.

---

# Основная идея

Toolkit превращает обнаруженное окружение в выбранное воспроизводимое состояние.

```text
Discover → Describe → Select → Bootstrap
```

Discovery анализирует существующий Mac. Generated Configuration описывает
обнаруженное состояние. Blueprint выбирает нужные категории и компоненты,
не дублируя их значения. Bootstrap безопасно применяет выбранное состояние.

---

# Как принимает решения Toolkit

Bootstrap не выполняет действия без проверки.

Каждое поддерживаемое действие следует общему принципу:

```text
Read Configuration → Check → Apply → Verify
```

Если изменение не требуется, Toolkit ничего не делает.

Если обнаружено отличие, Toolkit выполняет только необходимое действие.

---

# Основные принципы

Toolkit строится на следующих принципах.

- Idempotent
- Verify After Apply
- Quiet by Default
- Verbose When Needed
- Stateless Core
- Modular Architecture
- Discovery First
- Safe Handling of User Data

---

# Архитектура

```text
Discovery
    ↓
Generated Configuration
    ↓
Blueprint
    ↓
Bootstrap
```

Каждый уровень отвечает за одну задачу: Discovery ничего не изменяет,
Generated Configuration хранит обнаруженные значения, Blueprint хранит выбор,
а Bootstrap проверяет и применяет необходимые изменения.

Dry-run / Preview и Verification остаются запланированными возможностями.
Restore Engine и AI Assistant не являются обязательными частями этой модели.

---

# Что НЕ делает Toolkit

Toolkit не управляет пользовательскими данными.

Он никогда автоматически не выполняет:

- `git pull`
- `git reset --hard`
- `git clean`
- удаление пользовательских файлов

Все потенциально опасные действия должны выполняться пользователем осознанно.

---

# Конечная цель

После завершения проекта перенос рабочего окружения должен выглядеть следующим образом.

```
Старый Mac

↓

./bootstrap.sh --discover

↓

config/generated/

↓

./bootstrap.sh --blueprint

↓

Новый Mac

↓

./bootstrap.sh --bootstrap

↓

Полностью готовое рабочее окружение
```

Именно эта схема является основной идеей Mac Bootstrap Toolkit.

Возможное долгосрочное развитие этой модели описано в
[State Convergence](ideas/STATE-CONVERGENCE.ru.md).
