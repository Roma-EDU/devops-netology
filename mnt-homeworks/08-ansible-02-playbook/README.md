# 8.2. Работа с Playbook

**Ответ**: ссылка на [ветку в другом репозитории](https://github.com/Roma-EDU/ansible-netology/tree/08-ansible-02-playbook)

## Подготовка к выполнению

- [x] Создайте свой собственный (или используйте старый) публичный репозиторий на github с произвольным именем.
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

### Шаг 2. Добавляем конфигурацию терраформ для быстрого разворачивания (и сворачивания) инфрастурктуры

- Сами файлы лежат в репозитории в папке [terraform](https://github.com/Roma-EDU/ansible-netology/tree/08-ansible-02-playbook/terraform)
- По завершении получаем IP-адреса `external_ip_address_clickhouse_01` и `external_ip_address_application_01`, которые подставим в `inventory/prod.yml`

```bash
$ terraform init

Initializing the backend...

Initializing provider plugins...
- Finding latest version of yandex-cloud/yandex...
- Installing yandex-cloud/yandex v0.74.0...
- Installed yandex-cloud/yandex v0.74.0 (self-signed, key ID E40F590B50BB8E40)
...
Terraform has been successfully initialized!
...
$ terraform plan
...
$ terraform apply -auto-approve

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the
following symbols:
  + create

Terraform will perform the following actions:
...
Apply complete! Resources: 5 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_application_01 = "51.250.82.119"
external_ip_address_clickhouse_01 = "51.250.2.168"
external_ip_address_lighthouse_01 = "51.250.1.244"
internal_ip_address_application_01 = "192.168.10.21"
internal_ip_address_clickhouse_01 = "192.168.10.11"
internal_ip_address_lighthouse_01 = "192.168.10.31"

```

### Шаг 3. Установка линтера для ansible

```bash
$ pip3 install "ansible-lint"
Defaulting to user installation because normal site-packages is not writeable
...
Installing collected packages: commonmark, typing-extensions, subprocess-tee, ruamel.yaml.clib, pygments, pathspec, bracex, yamllint, wcmatch, ruamel.yaml, rich, ansible-compat, enrich, ansible-lint
Successfully installed ansible-compat-2.0.2 ansible-lint-6.0.2 bracex-2.2.1 commonmark-0.9.1 enrich-1.2.7 pathspec-0.9.0 pygments-2.12.0 rich-12.3.0 ruamel.yaml-0.17.21 ruamel.yaml.clib-0.2.6 subprocess-tee-0.3.5 typing-extensions-4.2.0 wcmatch-8.3 yamllint-1.26.3
```


## Основная часть

1. Приготовьте свой собственный inventory файл `prod.yml`.
   * **Ответ**: скопировал исходный `prod.yml`, отредактировал установку ClickHouse:
     * Разбил скачивание дистрибутива на разные шаги (noarch и x86_64) внутри блока, чтобы не было ошибок
     * Вынес создание базы в post_tasks (мне кажется более логичным + иначе нужно принудительно вызывать handler через `meta: flush_handlers`)
     * Добавил ожидание на запуск службы ClickHouse
2. Допишите playbook: нужно сделать ещё один play, который устанавливает и настраивает [vector](https://vector.dev).
   * **Ответ**: добавил новый play `Install Vector`
3. При создании tasks рекомендую использовать модули: `get_url`, `template`, `unarchive`, `file`.
   * **Ответ**: нашёл способ через rpm
4. Tasks должны: скачать нужной версии дистрибутив, выполнить распаковку в выбранную директорию, установить vector.
   * **Ответ**: через `get_url` скачиваем rpm и через `yum` устанавливаем его
5. Запустите `ansible-lint site.yml` и исправьте ошибки, если они есть.
   * **Ответ**: запустил, поправил ошибки (пробел в конце имени, полное имя модуля ansible.builtin.module_name, mode для скачиваемых файлов)
6. Попробуйте запустить playbook на этом окружении с флагом `--check`.
   * **Ответ**: запустил
7. Запустите playbook на `prod.yml` окружении с флагом `--diff`. Убедитесь, что изменения на системе произведены.
   * **Ответ**: убедился
8. Повторно запустите playbook с флагом `--diff` и убедитесь, что playbook идемпотентен.
   * **Ответ**: все play завершены со статусом `ok` (без `changed` и т.п.)
9. Подготовьте README.md файл по своему playbook. В нём должно быть описано: что делает playbook, какие у него есть параметры и теги.
   * **Ответ**: подготовил
10. Готовый playbook выложите в свой репозиторий, поставьте тег `08-ansible-02-playbook` на фиксирующий коммит, в ответ предоставьте ссылку на него.
    * **Ответ**: Ссылка на [ветку](https://github.com/Roma-EDU/ansible-netology/tree/08-ansible-02-playbook)
