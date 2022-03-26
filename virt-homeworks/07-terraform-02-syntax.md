# 7.2. Облачные провайдеры и синтаксис Terraform

Зачастую разбираться в новых инструментах гораздо интересней понимая то, как они работают изнутри. 
Поэтому в рамках первого *необязательного* задания предлагается завести свою учетную запись в AWS (Amazon Web Services) или Yandex.Cloud.
Идеально будет познакомится с обоими облаками, потому что они отличаются. 

## Задача 1 (вариант с AWS). Регистрация в aws и знакомство с основами (необязательно, но крайне желательно).

>Остальные задания можно будет выполнять и без этого аккаунта, но с ним можно будет увидеть полный цикл процессов. 
>
>AWS предоставляет достаточно много бесплатных ресурсов в первый год после регистрации, подробно описано [здесь](https://aws.amazon.com/free/).
>1. Создайте аккаут aws.
>1. Установите c aws-cli https://aws.amazon.com/cli/.
>1. Выполните первичную настройку aws-sli https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html.
>1. Создайте IAM политику для терраформа c правами
>    * AmazonEC2FullAccess
>    * AmazonS3FullAccess
>    * AmazonDynamoDBFullAccess
>    * AmazonRDSFullAccess
>    * CloudWatchFullAccess
>    * IAMFullAccess
>1. Добавьте переменные окружения 
>    ```
>    export AWS_ACCESS_KEY_ID=(your access key id)
>    export AWS_SECRET_ACCESS_KEY=(your secret access key)
>    ```
>1. Создайте, остановите и удалите ec2 инстанс (любой с пометкой `free tier`) через веб интерфейс. 
>
>В виде результата задания приложите вывод команды `aws configure list`.

**Ответ**: К сожалению, на данный момент в AWS невозможно зарегистрироваться новым позьзователям :( 

## Задача 1 (Вариант с Yandex.Cloud). Регистрация в ЯО и знакомство с основами (необязательно, но крайне желательно).

>1. Подробная инструкция на русском языке содержится [здесь](https://cloud.yandex.ru/docs/solutions/infrastructure-management/terraform-quickstart).
>2. Обратите внимание на период бесплатного использования после регистрации аккаунта. 
>3. Используйте раздел "Подготовьте облако к работе" для регистрации аккаунта. Далее раздел "Настройте провайдер" для подготовки
>базового терраформ конфига.
>4. Воспользуйтесь [инструкцией](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs) на сайте терраформа, что бы 
>не указывать авторизационный токен в коде, а терраформ провайдер брал его из переменных окружений.

**Ответ**

### Шаг 0*. Подготовка окружения

1. Регистрируемся на Yandex.Cloud (уже был аккаунт, поэтому без подробностей).
2. Устанавливаем terraform
   ```bash
   $ sudo apt-get update
   Hit:1 http://archive.ubuntu.com/ubuntu focal InRelease
   ...
   Fetched 18.4 MB in 7s (2490 kB/s)
   Reading package lists... Done
   $ curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
   OK
   $ sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
   Hit:1 http://archive.ubuntu.com/ubuntu focal InRelease
   ...
   Fetched 66.2 kB in 2s (34.7 kB/s)
   Reading package lists... Done
   $ sudo apt-get update && sudo apt-get install terraform
   Hit:1 http://security.ubuntu.com/ubuntu focal-security InRelease
   ...
   Setting up terraform (1.1.7) ...
   $ terraform -version
   Terraform v1.1.7
   on linux_amd64
   ```
3. Устанавливаем Yandex CLI
   ```bash
   $ curl https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
     % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                    Dload  Upload   Total   Spent    Left  Speed
   100  9739  100  9739    0     0   9284      0  0:00:01  0:00:01 --:--:--  9284
   Downloading yc 0.89.0
     % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                    Dload  Upload   Total   Spent    Left  Speed
   100 83.1M  100 83.1M    0     0  6363k      0  0:00:13  0:00:13 --:--:-- 8077k
   Yandex Cloud CLI 0.89.0 linux/amd64
   
   yc PATH has been added to your '/home/vagrant/.bashrc' profile
   yc bash completion has been added to your '/home/vagrant/.bashrc' profile.
   Now we have zsh completion. Type "echo 'source /home/vagrant/yandex-cloud/completion.zsh.inc' >>  ~/.zshrc" to install itTo complete installation, start a new shell (exec -l $SHELL) or type 'source "/home/vagrant/.bashrc"' in the current one
   $ echo 'source /home/vagrant/yandex-cloud/completion.zsh.inc' >>  ~/.zshrc
   $ source "/home/vagrant/.bashrc"
   $ yc -version
   Yandex Cloud CLI 0.89.0 linux/amd64
   ```

### Шаг 1. Инициализируем учётные данные

Инициализируем Yandex CLI для работы в своём облаке (папка `netology`, регион доступности `ru-central1-a`)
```bash
$ yc init
Welcome! This command will take you through the configuration process.
Pick desired action:
 [1] Re-initialize this profile 'default' with new settings
 [2] Create a new profile
Please enter your numeric choice: 1
Please go to https://oauth.yandex.ru/authorize?response_type=token&client_id=MY_CLIENT_ID in order to obtain OAuth token.

Please enter OAuth token: [XXXXXX*********************XXXXXX] MY_YC_TOKEN
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
```

### Шаг 2. Создаём сервисный аккаунт

В интерфейсе [Облако - Рабочая папка (netology) - Сервисные аккаунты](https://console.cloud.yandex.ru/folders/b1gr1vdb5g3ktr8v0877?section=service-accounts) 
создаём сервисный аккаунт `netology-service`, от имени которого будет работать terraform. И выдаём ему роль `admin`

**ВОПРОСЫ**:
1. Какую роль нужно на самом деле выдавать? Пробовал комбинацию `resource-manager.admin` и `vpc.admin` и их оказалось недостаточно.
2. Как корректно задать роль через консоль? Создаётся нормально, а вот догадаться как задать права через `set-access-bindings` у меня не получилось  
   ```bash
   $ yc iam service-account create netology-service
   id: ajebf9omlm5sed0thvci
   folder_id: b1gr1vdb5g3ktr8v0877
   created_at: "2022-03-26T13:15:02.993221991Z"
   name: netology-service
   
   $ yc iam service-account set-access-bindings netology-service --role resource-manager.admin
   ERROR: unknown flag: --role
   ```


## Задача 2. Создание aws ec2 или yandex_compute_instance через терраформ. 

>1. В каталоге `terraform` вашего основного репозитория, который был создан в начале курсе, создайте файл `main.tf` и `versions.tf`.
>2. Зарегистрируйте провайдер 
>   1. для [aws](https://registry.terraform.io/providers/hashicorp/aws/latest/docs). В файл `main.tf` добавьте
>   блок `provider`, а в `versions.tf` блок `terraform` с вложенным блоком `required_providers`. Укажите любой выбранный вами регион 
>   внутри блока `provider`.
>   2. либо для [yandex.cloud](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs). Подробную инструкцию можно найти 
>   [здесь](https://cloud.yandex.ru/docs/solutions/infrastructure-management/terraform-quickstart).
>3. Внимание! В гит репозиторий нельзя пушить ваши личные ключи доступа к аккаунту. Поэтому в предыдущем задании мы указывали
>их в виде переменных окружения. 
>4. В файле `main.tf` воспользуйтесь блоком `data "aws_ami` для поиска ami образа последнего Ubuntu.  
>5. В файле `main.tf` создайте рессурс 
>   1. либо [ec2 instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance).
>   Постарайтесь указать как можно больше параметров для его определения. Минимальный набор параметров указан в первом блоке 
>   `Example Usage`, но желательно, указать большее количество параметров.
>   2. либо [yandex_compute_image](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/compute_image).
>6. Также в случае использования aws:
>   1. Добавьте data-блоки `aws_caller_identity` и `aws_region`.
>   2. В файл `outputs.tf` поместить блоки `output` с данными об используемых в данный момент: 
>       * AWS account ID,
>       * AWS user ID,
>       * AWS регион, который используется в данный момент, 
>       * Приватный IP ec2 инстансы,
>       * Идентификатор подсети в которой создан инстанс.  
>7. Если вы выполнили первый пункт, то добейтесь того, что бы команда `terraform plan` выполнялась без ошибок. 
>
>
>В качестве результата задания предоставьте:
>1. Ответ на вопрос: при помощи какого инструмента (из разобранных на прошлом занятии) можно создать свой образ ami?
>1. Ссылку на репозиторий с исходной конфигурацией терраформа.  

**Ответ**

### Шаг 1. Создаём файлы для terraform

С помощью документации https://cloud.yandex.ru/docs/tutorials/infrastructure-management/terraform-quickstart и https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/compute_image заполняем необходимые параметры terraform

Папка с конфигурацией terraform https://github.com/Roma-EDU/devops-netology/tree/master/virt-homeworks/07-terraform-02-syntax
Образ можно выбрать из списка, предоставляемого YC, найти на их маркете или создать свой с помощью [Packer](https://www.packer.io)

**ВОПРОСЫ**
1. У меня не получилось указать выбор последнего доступного образа, как требуется в пункте 4 этой задачи. При этом у образа есть `family_id`. Можно ли им как-то воспользоваться применительно к этой задаче?

### Шаг 2. Генерируем ключи для работы

Формируем `key.json` с учётными данными от сервисного аккаунта и ssh-ключи для захода на созданные виртуалки

```bash
$ cd /vagrant/07-terraform-02-syntax
$ yc iam key create --service-account-name netology-service --output key.json
id: aje06gfgf4ouo44slbvg
service_account_id: ajebf9omlm5sed0thvci
created_at: "2022-03-26T13:28:26.669789945Z"
key_algorithm: RSA_2048

$ ssh-keygen
Generating public/private rsa key pair.
Enter file in which to save the key (/home/vagrant/.ssh/id_rsa):
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /home/vagrant/.ssh/id_rsa
Your public key has been saved in /home/vagrant/.ssh/id_rsa.pub
The key fingerprint is:
...
```

### Шаг 3. Запускаем terraform

```bash
$ terraform init

Initializing the backend...

Initializing provider plugins...
- Finding latest version of yandex-cloud/yandex...
- Installing yandex-cloud/yandex v0.72.0...
- Installed yandex-cloud/yandex v0.72.0 (self-signed, key ID E40F590B50BB8E40)

Partner and community providers are signed by their developers.
If you'd like to know more about provider signing, you can read about it here:
https://www.terraform.io/docs/cli/plugins/signing.html

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.

$ terraform plan

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated
with the following symbols:
  + create

Terraform will perform the following actions:

  # yandex_compute_instance.vm-1 will be created
  + resource "yandex_compute_instance" "vm-1" {
      + allow_stopping_for_update = true
      + created_at                = (known after apply)
      + folder_id                 = (known after apply)
      + fqdn                      = (known after apply)
      + hostname                  = "vm-1.netology.yc"
      + id                        = (known after apply)
...
Plan: 4 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + external_ip_address_vm_1 = (known after apply)
  + external_ip_address_vm_2 = (known after apply)
  + internal_ip_address_vm_1 = "192.168.10.11"
  + internal_ip_address_vm_2 = "192.168.10.12"

──────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly these actions
if you run "terraform apply" now.

$ terraform apply -auto-approve=true
...
yandex_compute_instance.vm-1: Still creating... [20s elapsed]
yandex_compute_instance.vm-2: Creation complete after 23s [id=fhm1u1c4gn5q6ietjbdn]
yandex_compute_instance.vm-1: Creation complete after 25s [id=fhmbc09cn41td9c8cm3c]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_vm_1 = "51.250.68.44"
external_ip_address_vm_2 = "51.250.71.138"
internal_ip_address_vm_1 = "192.168.10.11"
internal_ip_address_vm_2 = "192.168.10.12"
```

Проверяем, что доступны
```bash
$ ssh ubuntu@51.250.68.44
Welcome to Ubuntu 20.04.3 LTS (GNU/Linux 5.4.0-96-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

The programs included with the Ubuntu system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Ubuntu comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
applicable law.

To run a command as administrator (user "root"), use "sudo <command>".
See "man sudo_root" for details.

ubuntu@vm-1:~$ exit
logout
Connection to 51.250.68.44 closed.
```

### Шаг 4*. Удаляем ресурсы

С помощью terraform удаляем все созданные ресурсы
```bash
$ terraform destroy -auto-approve=true
...
yandex_compute_instance.vm-2: Destroying... [id=fhm1u1c4gn5q6ietjbdn]
yandex_compute_instance.vm-1: Destroying... [id=fhmbc09cn41td9c8cm3c]
yandex_compute_instance.vm-2: Still destroying... [id=fhm1u1c4gn5q6ietjbdn, 10s elapsed]
yandex_compute_instance.vm-1: Still destroying... [id=fhmbc09cn41td9c8cm3c, 10s elapsed]
yandex_compute_instance.vm-2: Destruction complete after 13s
yandex_compute_instance.vm-1: Destruction complete after 13s
yandex_vpc_subnet.subnet-1: Destroying... [id=e9bo46l3mujap4m0jvd4]
yandex_vpc_subnet.subnet-1: Destruction complete after 2s
yandex_vpc_network.network-1: Destroying... [id=enphvbgjjoihuffvr4j0]
yandex_vpc_network.network-1: Destruction complete after 1s

Destroy complete! Resources: 4 destroyed.
```
И не забываем удалить сервисный аккаунт
