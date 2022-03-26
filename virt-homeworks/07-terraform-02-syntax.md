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

1. В каталоге `terraform` вашего основного репозитория, который был создан в начале курсе, создайте файл `main.tf` и `versions.tf`.
2. Зарегистрируйте провайдер 
   1. для [aws](https://registry.terraform.io/providers/hashicorp/aws/latest/docs). В файл `main.tf` добавьте
   блок `provider`, а в `versions.tf` блок `terraform` с вложенным блоком `required_providers`. Укажите любой выбранный вами регион 
   внутри блока `provider`.
   2. либо для [yandex.cloud](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs). Подробную инструкцию можно найти 
   [здесь](https://cloud.yandex.ru/docs/solutions/infrastructure-management/terraform-quickstart).
3. Внимание! В гит репозиторий нельзя пушить ваши личные ключи доступа к аккаунту. Поэтому в предыдущем задании мы указывали
их в виде переменных окружения. 
4. В файле `main.tf` воспользуйтесь блоком `data "aws_ami` для поиска ami образа последнего Ubuntu.  
5. В файле `main.tf` создайте рессурс 
   1. либо [ec2 instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance).
   Постарайтесь указать как можно больше параметров для его определения. Минимальный набор параметров указан в первом блоке 
   `Example Usage`, но желательно, указать большее количество параметров.
   2. либо [yandex_compute_image](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/compute_image).
6. Также в случае использования aws:
   1. Добавьте data-блоки `aws_caller_identity` и `aws_region`.
   2. В файл `outputs.tf` поместить блоки `output` с данными об используемых в данный момент: 
       * AWS account ID,
       * AWS user ID,
       * AWS регион, который используется в данный момент, 
       * Приватный IP ec2 инстансы,
       * Идентификатор подсети в которой создан инстанс.  
7. Если вы выполнили первый пункт, то добейтесь того, что бы команда `terraform plan` выполнялась без ошибок. 


В качестве результата задания предоставьте:
1. Ответ на вопрос: при помощи какого инструмента (из разобранных на прошлом занятии) можно создать свой образ ami?
1. Ссылку на репозиторий с исходной конфигурацией терраформа.  
 
---

### Как cдавать задание

Выполненное домашнее задание пришлите ссылкой на .md-файл в вашем репозитории.

---
