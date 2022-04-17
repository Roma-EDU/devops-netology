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

### Шаг 1. Инициализируем Terraform

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

### Шаг 2. Создаём workspace

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


### Шаг 3. Добавляем зависимость типа инстанса от workspace

В отличии от AWS, где характеристики машины определяется типом инстанса (t2.micro, t3.large), на YC можно просто указать требуемое количество ядер и памяти.
Поэтому в конфигурации именно эти параметры будут зависеть от workspace

Добавляем объект locals, в котором двумя способами будут описаны зависимости
```tf
locals {
  is_prod = terraform.workspace == "prod"
  memory_map = {
    default  = 4
    prod     = 8
    stage    = 2
  }
}
```

И прописываем зависимость характеристик машины
```tf
resource "yandex_compute_instance" "site-vm" {
  ...
  resources {
    cores  = local.is_prod ? 4 : 2
    memory = local.memory_map[terraform.workspace]
  }
  ...
```


### Шаг 4. Добавляем зависимость количества инстансов через count

Добавим задание `count`, чтобы для `stage` поднимался один инстанс, а для `prod` - сразу два.
```tf
resource "yandex_compute_instance" "site-vm" {
  zone      = var.yandex_zone
  allow_stopping_for_update = true
  count     = local.is_prod ? 2 : 1
  ...
```

И раз теперь поднимается несколько экземляров, отредактируем output на использование массива значений
```tf
output "internal_ip_address_site-vm" {
  value = [yandex_compute_instance.site-vm.*.network_interface.0.ip_address]
}

output "external_ip_address_site-vm" {
  value = [yandex_compute_instance.site-vm.*.network_interface.0.nat_ip_address]
}
```


### Шаг 5. Добавляем зависимость количества инстансов через for_each

Добавим поднятие 1 инстанса "мониторинга" для `prod` и 0 для `stage`. 
Для этого в locals добавим переменную `monitoring_map`, представляющий массив уникальных строк и новый ресурс "monitoring-vm", создаваемый через for_each  = toset( local.monitoring_map[terraform.workspace] )

```tf
locals {
  is_prod = terraform.workspace == "prod"
  memory_map = {
    default  = 4
    prod     = 8
    stage    = 2
  }
  monitoring_map = {
    prod     = ["m1"]
    stage    = []
  }
}

...

resource "yandex_compute_instance" "monitoring-vm" {
  for_each  = toset( local.monitoring_map[terraform.workspace] )
  zone      = var.yandex_zone
  allow_stopping_for_update = true
  
  resources {
    cores  = 2
    memory = 2
  }

  ...
```

### Шаг 6. Параметры жизненного цикла

Что бы при изменении настроек не возникло ситуации, когда не будет ни одного работающего инстанса "сайта", добавим параметр жизненного цикла `create_before_destroy = true`

```tf
resource "yandex_compute_instance" "site-vm" {
  ...
  lifecycle {
    create_before_destroy = true
  }
  ...
}
```

### Шаг 7. Выполнение

Переключаемся на `prod` и применяем изменения

```bash
$ terraform workspace select prod
Switched to workspace "prod".
$ terraform plan

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the
following symbols:
  + create

Terraform will perform the following actions:

  # yandex_compute_instance.monitoring-vm["m1"] will be created
  + resource "yandex_compute_instance" "monitoring-vm" {
      + allow_stopping_for_update = true
      + created_at                = (known after apply)
      + folder_id                 = (known after apply)
      + fqdn                      = (known after apply)
      + hostname                  = (known after apply)
      + id                        = (known after apply)
      + metadata                  = {
          + "ssh-keys" = <<-EOT
                ubuntu:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDxA5h6HsvBxzUtWSPLPU5Pa3S+aZIplzasNxMsZdyn4KhwGOFhaorDZR2k6nK3iKRq3zCUjnvFGB1W6sskWDGMfhStv7SxBhQvABxjt7+55rVCFxDr+fmTb6mSyVQWV6hiNZ7SyS3zwhJn8gEqg4l8BUfc5+O7yAAAiVp07xe39/JGOhZZxCLwB79PTDQBF/2kWQhmobnUOheggnuYYhJVZNHp871s8TlIRoYBRrdzrxJRF4QaeA00JYXLMD3C4ELUWNAXREmVEmCQVx+Wqtz4vvgiKppf+4qzLIh/2qjA9ag8um9NEcr9nc7mrgXWfleNmeKQVlXQ64EJ66kTO6RL6R9GfANuXAPzi3sUUSJ0FKg0gaOk3dpqkN+hJUkmG1GDDnR1dkWQBCLZcmUex2mZe4fYhND+38OAGhSjYHOINDlpf7H/JMne3j1HU+dhfM3RYhL3mZYDNJYazDjMiv+EUF1NzIK8zb30sczJAqHjYB9vO16L8OOLk8vhvFKV5w0= vagrant@ubuntu-focal
            EOT
        }
      + network_acceleration_type = "standard"
      + platform_id               = "standard-v1"
      + service_account_id        = (known after apply)
      + status                    = (known after apply)
      + zone                      = "ru-central1-a"

      + boot_disk {
          + auto_delete = true
          + device_name = (known after apply)
          + disk_id     = (known after apply)
          + mode        = (known after apply)

          + initialize_params {
              + block_size  = (known after apply)
              + description = (known after apply)
              + image_id    = "fd8mfc6omiki5govl68h"
              + name        = (known after apply)
              + size        = 10
              + snapshot_id = (known after apply)
              + type        = "network-nvme"
            }
        }

      + network_interface {
          + index              = (known after apply)
          + ip_address         = (known after apply)
          + ipv4               = true
          + ipv6               = (known after apply)
          + ipv6_address       = (known after apply)
          + mac_address        = (known after apply)
          + nat                = true
          + nat_ip_address     = (known after apply)
          + nat_ip_version     = (known after apply)
          + security_group_ids = (known after apply)
          + subnet_id          = (known after apply)
        }

      + placement_policy {
          + host_affinity_rules = (known after apply)
          + placement_group_id  = (known after apply)
        }

      + resources {
          + core_fraction = 100
          + cores         = 1
          + memory        = 2
        }

      + scheduling_policy {
          + preemptible = (known after apply)
        }
    }

  # yandex_compute_instance.site-vm[0] will be created
  + resource "yandex_compute_instance" "site-vm" {
      + allow_stopping_for_update = true
      + created_at                = (known after apply)
      + folder_id                 = (known after apply)
      + fqdn                      = (known after apply)
      + hostname                  = (known after apply)
      + id                        = (known after apply)
      + metadata                  = {
          + "ssh-keys" = <<-EOT
                ubuntu:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDxA5h6HsvBxzUtWSPLPU5Pa3S+aZIplzasNxMsZdyn4KhwGOFhaorDZR2k6nK3iKRq3zCUjnvFGB1W6sskWDGMfhStv7SxBhQvABxjt7+55rVCFxDr+fmTb6mSyVQWV6hiNZ7SyS3zwhJn8gEqg4l8BUfc5+O7yAAAiVp07xe39/JGOhZZxCLwB79PTDQBF/2kWQhmobnUOheggnuYYhJVZNHp871s8TlIRoYBRrdzrxJRF4QaeA00JYXLMD3C4ELUWNAXREmVEmCQVx+Wqtz4vvgiKppf+4qzLIh/2qjA9ag8um9NEcr9nc7mrgXWfleNmeKQVlXQ64EJ66kTO6RL6R9GfANuXAPzi3sUUSJ0FKg0gaOk3dpqkN+hJUkmG1GDDnR1dkWQBCLZcmUex2mZe4fYhND+38OAGhSjYHOINDlpf7H/JMne3j1HU+dhfM3RYhL3mZYDNJYazDjMiv+EUF1NzIK8zb30sczJAqHjYB9vO16L8OOLk8vhvFKV5w0= vagrant@ubuntu-focal
            EOT
        }
      + network_acceleration_type = "standard"
      + platform_id               = "standard-v1"
      + service_account_id        = (known after apply)
      + status                    = (known after apply)
      + zone                      = "ru-central1-a"

      + boot_disk {
          + auto_delete = true
          + device_name = (known after apply)
          + disk_id     = (known after apply)
          + mode        = (known after apply)

          + initialize_params {
              + block_size  = (known after apply)
              + description = (known after apply)
              + image_id    = "fd8mfc6omiki5govl68h"
              + name        = (known after apply)
              + size        = 20
              + snapshot_id = (known after apply)
              + type        = "network-nvme"
            }
        }

      + network_interface {
          + index              = (known after apply)
          + ip_address         = (known after apply)
          + ipv4               = true
          + ipv6               = (known after apply)
          + ipv6_address       = (known after apply)
          + mac_address        = (known after apply)
          + nat                = true
          + nat_ip_address     = (known after apply)
          + nat_ip_version     = (known after apply)
          + security_group_ids = (known after apply)
          + subnet_id          = (known after apply)
        }

      + placement_policy {
          + host_affinity_rules = (known after apply)
          + placement_group_id  = (known after apply)
        }

      + resources {
          + core_fraction = 100
          + cores         = 4
          + memory        = 8
        }

      + scheduling_policy {
          + preemptible = (known after apply)
        }
    }

  # yandex_compute_instance.site-vm[1] will be created
  + resource "yandex_compute_instance" "site-vm" {
      + allow_stopping_for_update = true
      + created_at                = (known after apply)
      + folder_id                 = (known after apply)
      + fqdn                      = (known after apply)
      + hostname                  = (known after apply)
      + id                        = (known after apply)
      + metadata                  = {
          + "ssh-keys" = <<-EOT
                ubuntu:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDxA5h6HsvBxzUtWSPLPU5Pa3S+aZIplzasNxMsZdyn4KhwGOFhaorDZR2k6nK3iKRq3zCUjnvFGB1W6sskWDGMfhStv7SxBhQvABxjt7+55rVCFxDr+fmTb6mSyVQWV6hiNZ7SyS3zwhJn8gEqg4l8BUfc5+O7yAAAiVp07xe39/JGOhZZxCLwB79PTDQBF/2kWQhmobnUOheggnuYYhJVZNHp871s8TlIRoYBRrdzrxJRF4QaeA00JYXLMD3C4ELUWNAXREmVEmCQVx+Wqtz4vvgiKppf+4qzLIh/2qjA9ag8um9NEcr9nc7mrgXWfleNmeKQVlXQ64EJ66kTO6RL6R9GfANuXAPzi3sUUSJ0FKg0gaOk3dpqkN+hJUkmG1GDDnR1dkWQBCLZcmUex2mZe4fYhND+38OAGhSjYHOINDlpf7H/JMne3j1HU+dhfM3RYhL3mZYDNJYazDjMiv+EUF1NzIK8zb30sczJAqHjYB9vO16L8OOLk8vhvFKV5w0= vagrant@ubuntu-focal
            EOT
        }
      + network_acceleration_type = "standard"
      + platform_id               = "standard-v1"
      + service_account_id        = (known after apply)
      + status                    = (known after apply)
      + zone                      = "ru-central1-a"

      + boot_disk {
          + auto_delete = true
          + device_name = (known after apply)
          + disk_id     = (known after apply)
          + mode        = (known after apply)

          + initialize_params {
              + block_size  = (known after apply)
              + description = (known after apply)
              + image_id    = "fd8mfc6omiki5govl68h"
              + name        = (known after apply)
              + size        = 20
              + snapshot_id = (known after apply)
              + type        = "network-nvme"
            }
        }

      + network_interface {
          + index              = (known after apply)
          + ip_address         = (known after apply)
          + ipv4               = true
          + ipv6               = (known after apply)
          + ipv6_address       = (known after apply)
          + mac_address        = (known after apply)
          + nat                = true
          + nat_ip_address     = (known after apply)
          + nat_ip_version     = (known after apply)
          + security_group_ids = (known after apply)
          + subnet_id          = (known after apply)
        }

      + placement_policy {
          + host_affinity_rules = (known after apply)
          + placement_group_id  = (known after apply)
        }

      + resources {
          + core_fraction = 100
          + cores         = 4
          + memory        = 8
        }

      + scheduling_policy {
          + preemptible = (known after apply)
        }
    }

  # yandex_vpc_network.network-1 will be created
  + resource "yandex_vpc_network" "network-1" {
      + created_at                = (known after apply)
      + default_security_group_id = (known after apply)
      + folder_id                 = (known after apply)
      + id                        = (known after apply)
      + labels                    = (known after apply)
      + name                      = "network1"
      + subnet_ids                = (known after apply)
    }

  # yandex_vpc_subnet.subnet-1 will be created
  + resource "yandex_vpc_subnet" "subnet-1" {
      + created_at     = (known after apply)
      + folder_id      = (known after apply)
      + id             = (known after apply)
      + labels         = (known after apply)
      + name           = "subnet1"
      + network_id     = (known after apply)
      + v4_cidr_blocks = [
          + "192.168.10.0/24",
        ]
      + v6_cidr_blocks = (known after apply)
      + zone           = "ru-central1-a"
    }

Plan: 5 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + external_ip_address_site-vm = [
      + [
          + (known after apply),
          + (known after apply),
        ],
    ]
  + internal_ip_address_site-vm = [
      + [
          + (known after apply),
          + (known after apply),
        ],
    ]

───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly these actions if
you run "terraform apply" now.

$ terraform apply -auto-approve
...
Apply complete! Resources: 3 added, 0 changed, 2 destroyed.

Outputs:

external_ip_address_site-vm = [
  [
    "51.250.82.12",
    "51.250.82.3",
  ],
]
internal_ip_address_site-vm = [
  [
    "192.168.10.16",
    "192.168.10.34",
  ],
]
```


### Шаг 8*. Удаляем всё

Чтобы не расходовать средства, не забываем всё удалить
1. Созданное терраформом
   ```bash
   $ terraform destroy -auto-approve
   ...
   ```
2. Созданное руками: хранилище и сервисный аккаунт
