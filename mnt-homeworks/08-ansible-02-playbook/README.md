# 8.2. Работа с Playbook

## Подготовка к выполнению

- [x] Создайте свой собственный (или используйте старый) публичный репозиторий на github с произвольным именем.
   * **Ответ**: добавил репозиторий [ansible-netology](https://github.com/Roma-EDU/ansible-netology)
- [x] Скачайте [playbook](https://github.com/netology-code/mnt-homeworks/tree/MNT-13/08-ansible-02-playbook/playbook) из репозитория 
с домашним заданием и перенесите его в свой репозиторий.
- [x] Подготовьте хосты в соответствии с группами из предподготовленного playbook.

### Шаг 1. Подключение к Yandex Cloud

- Переходим в рабочую папку для терраформа
- Подключаемся к Yandex Cloud
- Генерируем ключ для работы (сервисный аккаунт `terraform-service-account` уже создан через [консоль](https://console.cloud.yandex.ru/folders/b1gr1vdb5g3ktr8v0877?section=service-accounts) 
с ролью `editor`)

```bash
$ cd /vagrant/08-ansible-02-playbook/terraform/
$ yc init
Welcome! This command will take you through the configuration process.
Pick desired action:
 [1] Re-initialize this profile 'default' with new settings
 [2] Create a new profile
Please enter your numeric choice: 1
Please go to https://oauth.yandex.ru/authorize?response_type=token&client_id=MY_CLIENT_ID in order to obtain OAuth token.

Please enter OAuth token: [TOKEN_START*********************TOKEN_END] MY_OAUTH_TOKEN
You have one cloud available: 'cloud-roma' (id = b1gjn3v7sno758hjjba0). It is going to be used by default.
Please choose folder to use:
 [1] default (id = b1gdbsrbugl140ih7lgp)
 [2] netology (id = b1gr1vdb5g3ktr8v0877)
 [3] Create a new folder
Please enter your numeric choice: 2
Your current folder has been set to 'netology' (id = b1gr1vdb5g3ktr8v0877).
Do you want to configure a default Compute zone? [Y/n]
Which zone do you want to use as a profile default?
 [1] ru-central1-a
 [2] ru-central1-b
 [3] ru-central1-c
 [4] Don't set default zone
Please enter your numeric choice: 1
Your profile default Compute zone has been set to 'ru-central1-a'.
There is a new yc version '0.90.0' available. Current version: '0.89.0'.
See release notes at https://cloud.yandex.ru/docs/cli/release-notes
You can install it by running the following command in your shell:
        $ yc components update
        
$ yc iam key create --service-account-name terraform-service-account --output key.json
id: ajekuf62gvurockfdlig
service_account_id: ajeihsavo1fjqnkf82no
created_at: "2022-05-02T20:22:29.841583734Z"
key_algorithm: RSA_2048
```


## Основная часть

1. Приготовьте свой собственный inventory файл `prod.yml`.
2. Допишите playbook: нужно сделать ещё один play, который устанавливает и настраивает [vector](https://vector.dev).
3. При создании tasks рекомендую использовать модули: `get_url`, `template`, `unarchive`, `file`.
4. Tasks должны: скачать нужной версии дистрибутив, выполнить распаковку в выбранную директорию, установить vector.
5. Запустите `ansible-lint site.yml` и исправьте ошибки, если они есть.
6. Попробуйте запустить playbook на этом окружении с флагом `--check`.
7. Запустите playbook на `prod.yml` окружении с флагом `--diff`. Убедитесь, что изменения на системе произведены.
8. Повторно запустите playbook с флагом `--diff` и убедитесь, что playbook идемпотентен.
9. Подготовьте README.md файл по своему playbook. В нём должно быть описано: что делает playbook, какие у него есть параметры и теги.
10. Готовый playbook выложите в свой репозиторий, поставьте тег `08-ansible-02-playbook` на фиксирующий коммит, в ответ предоставьте ссылку на него.
