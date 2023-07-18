# 15.1. Организация сети»

## Подготовка к выполнению задания

### Шаг 1. Устанавливаем terraform

Согласно [инструкции](https://cloud.yandex.ru/docs/tutorials/infrastructure-management/terraform-quickstart) скачиваем с зеркала 
подходящую версию terraform (актуальная на сегодня terraform_1.5.3_linux_amd64.zip), распаковываем, копируем в папку "с программами"
и прописываем путь к нему.
```bash
$ sudo cp /vagrant/terraform /opt/
$ export PATH=$PATH:/opt/
$ terraform --version
Terraform v1.5.3
on linux_amd64
```

### Шаг 2. Устанавливаем Yandex Cloud CLI

```bash
$ curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
Downloading yc 0.108.1
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  100M  100  100M    0     0  10.3M      0  0:00:09  0:00:09 --:--:-- 10.6M
Yandex Cloud CLI 0.108.1 linux/amd64

yc PATH has been added to your '/home/vagrant/.bashrc' profile
yc bash completion has been added to your '/home/vagrant/.bashrc' profile.
Now we have zsh completion. Type "echo 'source /home/vagrant/yandex-cloud/completion.zsh.inc' >>  ~/.zshrc" to install it
To complete installation, start a new shell (exec -l $SHELL) or type 'source "/home/vagrant/.bashrc"' in the current one
$ echo 'source /home/vagrant/yandex-cloud/completion.zsh.inc' >>  ~/.zshrc
$ source "/home/vagrant/.bashrc"
$ yc --version
Yandex Cloud CLI 0.108.1 linux/amd64
```

### Шаг 3. Конфигурируем Yandex Cloud CLI

Инициализируем Yandex Cloud CLI
```bash
$ yc init
Welcome! This command will take you through the configuration process.
Please go to https://oauth.yandex.ru/authorize?response_type=token&client_id=<MY_CLIENT_ID> in order to obtain OAuth token.

Please enter OAuth token: <MY_ACCESS_TOKEN>
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
```

И создаём файлик для сервисного аккаунта (сам аккаунт уже создан в WEB-консоли с ролью `editor`)
```bash
$ yc iam key create --service-account-id aje16dilsetnl7cjm5na --output key.json
id: ajek0a9jv0u5m7pjru49
service_account_id: aje16dilsetnl7cjm5na
created_at: "2023-07-18T17:18:03.641491028Z"
key_algorithm: RSA_2048
```

### Шаг 4. Конфигурируем terraform на использование Yandex Provider

Открываем в редакторе файлик `nano ~/.terraformrc` и записываем в него настройки для установки провайдера
```bash
provider_installation {
  network_mirror {
    url = "https://terraform-mirror.yandexcloud.net/"
    include = ["registry.terraform.io/*/*"]
  }
  direct {
    exclude = ["registry.terraform.io/*/*"]
  }
}
```

Создаём файлик [provider.tf](./provider.tf) и инициализируем terraform
```bash
$ terraform init

Initializing the backend...

Initializing provider plugins...
- Finding latest version of yandex-cloud/yandex...
- Installing yandex-cloud/yandex v0.95.0...
- Installed yandex-cloud/yandex v0.95.0 (unauthenticated)

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

╷
│ Warning: Incomplete lock file information for providers
│
│ Due to your customized provider installation methods, Terraform was forced to calculate lock file checksums locally
│ for the following providers:
│   - yandex-cloud/yandex
│
│ The current .terraform.lock.hcl file only includes checksums for linux_amd64, so Terraform running on another
│ platform will fail to install these providers.
│
│ To calculate additional checksums for another platform, run:
│   terraform providers lock -platform=linux_amd64
│ (where linux_amd64 is the platform to generate)
╵

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```


## Задание 1. Yandex Cloud 

>**Что нужно сделать**
>
>1. Создать пустую VPC. Выбрать зону.
>2. Публичная подсеть.
> - Создать в VPC subnet с названием public, сетью `192.168.10.0/24`.
> - Создать в этой подсети NAT-инстанс, присвоив ему адрес `192.168.10.254`. В качестве `image_id` использовать `fd80mrhj8fl2oe87o4e1`.
> - Создать в этой публичной подсети виртуалку с публичным IP, подключиться к ней и убедиться, что есть доступ к интернету.
>3. Приватная подсеть.
> - Создать в VPC subnet с названием private, сетью `192.168.20.0/24`.
> - Создать route table. Добавить статический маршрут, направляющий весь исходящий трафик private сети в NAT-инстанс.
> - Создать в этой приватной подсети виртуалку с внутренним IP, подключиться к ней через виртуалку, созданную ранее, и убедиться, что есть доступ к интернету.
