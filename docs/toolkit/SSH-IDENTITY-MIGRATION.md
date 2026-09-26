# Secure SSH Identity Migration

Stage 12 v1 переносит явно выбранные существующие SSH identities отдельно от
Discovery, Generated Configuration, Blueprint и Bootstrap. Для отдельной
команды `age` и Python 3 должны быть доступны; сама команда их не устанавливает.

На исходном Mac сначала выполните Discovery и сохраните Blueprint. Homebrew
Discovery включает явно установленный `age` в список formulae; выберите его
в разделе Homebrew packages Blueprint. Если `age` установлен после последнего
Discovery, обновите Generated Configuration. Подготовьте и передайте обычное
локальное состояние Toolkit по [Quick Start](../getting-started/QUICKSTART.md),
затем отдельно экспортируйте выбранные SSH identities в защищённый пакет.

На целевом Mac сначала выполните обычные Preview и Bootstrap. Выбранный `age`
будет установлен вместе с другими Homebrew formulae, если отсутствует. После
этого отдельно запустите import пакета. SSH private identities не входят в
Generated Configuration, Blueprint или обычный Bootstrap; Toolkit не запускает
import автоматически. Если `age` не был выбран, обеспечьте его наличие до
запуска import.

Из корня репозитория:

```bash
./scripts/ssh-identity-migrate.sh list
./scripts/ssh-identity-migrate.sh export --output /absolute/path/package.age
./scripts/ssh-identity-migrate.sh import --input /absolute/path/package.age
```

`export` показывает подходящие пары под `~/.ssh`, принимает номера через терминал,
показывает выбор и требует точное `export`. `age` запрашивает passphrase через
терминал. Пакет не перезаписывает существующий файл. Перед передачей пакета
пользователь сам выбирает защищённый канал; passphrase следует передать отдельно.
Если `ssh-keygen` подтверждает неверную passphrase защищённого SSH key, команда
даёт до трёх интерактивных попыток и затем исключает эту пару с отдельным
сообщением. Другие ошибки проверки не вызывают повторного запроса.

`import` запрашивает passphrase, полностью проверяет пакет и показывает план.
Любой конфликт блокирует весь перенос. Идентичные пары не меняются. Для новых
пар требуется точное `import`. Существующие ключи никогда не заменяются.

Поддерживаются прямые файлы OpenSSH Ed25519, RSA и ECDSA nistp256/nistp384/
nistp521 с соответствующим `.pub`, владельцем текущим пользователем и режимами
`0600` для private и `0600` или `0644` для public; каталог `~/.ssh` должен иметь
режим `0700`. Symlinks, hard links,
ключи FIDO, DSA, сертификаты, agent state, known_hosts и Keychain вне v1.

Пакет — age passphrase ciphertext с tar и строгим manifest версии 1. Внутри
архива сначала идёт `manifest`, затем упорядоченные пары `keys/<name>` и
`keys/<name>.pub`. Manifest содержит magic `toolkit-ssh-identities`, `version=1`,
`count=N` и по одной tab-separated записи на пару: имя, тип, SHA-256 fingerprint,
размер и SHA-256 private, размер и SHA-256 public. Максимум 32 пары, 1 MiB на
каждый файл и 32 MiB на пакет. Открытый tar при export не создаётся;
выбранные пары временно копируются в приватный каталог под `/private/tmp`.
При import открытый tar временно находится там же как файл `0600`.
Каталоги имеют режим `0700` и удаляются при завершении или SIGINT/SIGTERM.
После SIGKILL или отключения питания могут остаться временные файлы либо
неполная новая пара в `~/.ssh`: проверьте `/private/tmp/ssh-migrate-*` и целевые
имена вручную. Успех Verify означает локальную проверку файлов и пары ключей;
сетевую аутентификацию Toolkit не проверяет.

Коды: `0` — успех или идентичное состояние, `1` — отмена/конфликт,
`2` — ошибка проверки, зависимости, шифрования или публикации,
`130` — прерывание сигналом.
