# 7.3. Основы и принцип работы Терраформ

## Задача 1. Создадим бэкэнд в S3 (необязательно, но крайне желательно).

>Если в рамках предыдущего задания у вас уже есть аккаунт AWS, то давайте продолжим знакомство со взаимодействием
>терраформа и aws. 
>
>1. Создайте s3 бакет, iam роль и пользователя от которого будет работать терраформ. Можно создать отдельного пользователя,
>а можно использовать созданного в рамках предыдущего задания, просто добавьте ему необходимы права, как описано 
>[здесь](https://www.terraform.io/docs/backends/types/s3.html).
>1. Зарегистрируйте бэкэнд в терраформ проекте как описано по ссылке выше. 

**Ответ**

### Шаг 1. Создаём бакет на Yandex.Cloud и сервисный аккаунт

Пользуемся официальной документацией [Загрузка состояний Terraform в Object Storage](https://cloud.yandex.ru/docs/tutorials/infrastructure-management/terraform-state-storage)

1. В [веб-консоли](https://console.cloud.yandex.ru/cloud?section=overview) переходим в рабочий каталог `netology` 
2. Создаём `Object Storage` с уникальным именем `terraform-object-storage-tutorial-unique-xsas23` (думаю 5 Гб хватит на хранение состояний)
   * **Вопрос 1**: уникальность должна быть для всего Yandex.Cloud? Например terraform-object-storage-tutorial не захотел создаваться
3. Создаём сервисный аккаунт `terraform-service-account` с ролью `editor` 
4. Получаем для него статический ключ доступа (через команду `+ Создать новый ключ` в правом верхнем углу), копируем 2 значения `<SA_ACCESS_KEY>` и `<SA_SECRET_KEY>`
   * **Вопрос 2**: а через использование ключа из `yc iam key create --service-account-name terraform-service-account
--output key.json` никак нельзя настроить?

### Шаг 2. Добавляем использование бэкэнда в S3

Добавляем backend с типом [S3](https://www.terraform.io/language/settings/backends/s3) в объект terraform 
* **Вопрос 3**: переменными совсем нельзя пользоваться? Например я хотел указать `region: var.yandex_zone`

```tf
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"

  backend "s3" {
    endpoint   = "storage.yandexcloud.net"
    bucket     = "terraform-object-storage-tutorial-unique-xsas23"
    region     = "ru-central1-a"
    key        = "states/terraform.tfstate"
    access_key = "<SA_ACCESS_KEY>"
    secret_key = "<SA_SECRET_KEY>"

    skip_region_validation      = true
    skip_credentials_validation = true
  }
}
```

### Шаг 3. Проверяем установленные версии и инициализируем Yandex-CLI

```bash
$ terraform --version
Terraform v1.1.7
on linux_amd64

Your version of Terraform is out of date! The latest version
is 1.1.8. You can update by downloading from https://www.terraform.io/downloads.html

$ yc -version
Yandex Cloud CLI 0.89.0 linux/amd64

$ yc init
Welcome! This command will take you through the configuration process.
Pick desired action:
 [1] Re-initialize this profile 'default' with new settings
 [2] Create a new profile
Please enter your numeric choice: 1
Please go to https://oauth.yandex.ru/authorize?response_type=token&client_id=MY_CLIENT_ID in order to obtain OAuth token.

Please enter OAuth token: [A*********************g] MY_AUTH_TOKEN
You have one cloud available: 'cloud-roma' (id = b1gjn3v7sno758hjjba0). It is going to be used by default.
Please choose folder to use:
 [1] default (id = b1gdbsrbugl140ih7lgp)
 [2] netology (id = b1gr1vdb5g3ktr8v0877)
 [3] Create a new folder
Please enter your numeric choice: 2
Your current folder has been set to 'netology' (id = b1gr1vdb5g3ktr8v0877).
Do you want to configure a default Compute zone? [Y/n] y
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
```

### Шаг 4. Инициализируем Terraform

Переходим в рабочую папку с файлами terraform, получаем ключ `key.json` от сервисного аккаунта для работы и инициализируем Terraform
```bash
$ cd /vagrant/07-terraform-03-basic/
$ yc iam key create --service-account-name terraform-service-account --output key.json
id: aje1n4v54s28o5n8r3b8
service_account_id: ajeade9r55pfhdbd5sdj
created_at: "2022-04-17T11:08:40.151263607Z"
key_algorithm: RSA_2048
$ terraform init

Initializing the backend...

Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.

Initializing provider plugins...
- Finding latest version of yandex-cloud/yandex...
- Installing yandex-cloud/yandex v0.73.0...
...
```


## Задача 2. Инициализируем проект и создаем воркспейсы. 

>1. Выполните `terraform init`:
>    * если был создан бэкэнд в S3, то терраформ создат файл стейтов в S3 и запись в таблице 
>dynamodb.
>    * иначе будет создан локальный файл со стейтами.  
>1. Создайте два воркспейса `stage` и `prod`.
>1. В уже созданный `aws_instance` добавьте зависимость типа инстанса от вокспейса, что бы в разных ворскспейсах 
>использовались разные `instance_type`.
>1. Добавим `count`. Для `stage` должен создаться один экземпляр `ec2`, а для `prod` два. 
>1. Создайте рядом еще один `aws_instance`, но теперь определите их количество при помощи `for_each`, а не `count`.
>1. Что бы при изменении типа инстанса не возникло ситуации, когда не будет ни одного инстанса добавьте параметр
>жизненного цикла `create_before_destroy = true` в один из ресурсов `aws_instance`.
>1. При желании поэкспериментируйте с другими параметрами и ресурсами.
>
>В виде результата работы пришлите:
>* Вывод команды `terraform workspace list`.
>* Вывод команды `terraform plan` для воркспейса `prod`.  

**Ответ**

### Шаг 1. Создаём workspace

Добавим два новых workspace: `prod` и `stage` (`default` трогать не надо)
```bash
$ terraform workspace new prod
Created and switched to workspace "prod"!

You're now on a new, empty workspace. Workspaces isolate their state,
so if you run "terraform plan" Terraform will not see any existing state
for this configuration.
$ terraform workspace new stage
Created and switched to workspace "stage"!

You're now on a new, empty workspace. Workspaces isolate their state,
so if you run "terraform plan" Terraform will not see any existing state
for this configuration.
$ terraform workspace list
  default
  prod
* stage
```
P.S. Если зайти на Object Storage, то там увидим папку `env:`, внутри которой появились подпапки, соответствующие workspace, а именно `prod` и `stage`

