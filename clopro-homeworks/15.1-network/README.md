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

### Шаг 1. Создаём конфигурацию сервера согласно требованиям

Обкладываемся документацией (вкладкой Terraform)
* <https://terraform-provider.yandexcloud.net/Resources/compute_instance>
* <https://cloud.yandex.ru/docs/compute/operations/vm-create/create-linux-vm>
* <https://cloud.yandex.ru/docs/vpc/operations/static-route-create>
* <https://cloud.yandex.ru/docs/tutorials/routing/nat-instance>
* и так далее

И получаем конфигурационные файлы: 
* основной [main.tf](./main.tf) - содержит описание желаемых ресурсов
* вспомогательный [provider.tf](./provider.tf) - встречался нам ранее, уговаривает Terraform пользоваться правильным провайдером
* вспомогательный [variables.tf](./variables.tf) - содержит список переменных (чтобы задавать в одном месте)
* вспомогательный [output.tf](./output.tf) - для вывода в консоль получившихся IP (чтобы не искать, куда потом подключаться)

### Шаг 2. Накатываем изменения

```bash
$ terraform plan

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the
following symbols:
  + create
...
$ terraform apply -auto-approve

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the
following symbols:
  + create

Terraform will perform the following actions:

  # yandex_compute_instance.nat-vm-1 will be created
  + resource "yandex_compute_instance" "nat-vm-1" {
...
Apply complete! Resources: 7 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_nat-vm = "158.160.46.111"
external_ip_address_private-vm-1 = ""
external_ip_address_public-vm-1 = "158.160.52.236"
internal_ip_address_nat-vm = "192.168.10.254"
internal_ip_address_private-vm-1 = "192.168.20.4"
internal_ip_address_public-vm-1 = "192.168.10.19"
```

### Шаг 3. Проверяем доступ в интернет

Подключаемся к инстансу из публичной подсети и проверяем его доступ в интернет `ping 8.8.8.8`
```bash
$ ssh ubuntu@158.160.52.236
The authenticity of host '158.160.52.236 (158.160.52.236)' can't be established.
ED25519 key fingerprint is SHA256:E5ThAx03wmZmYWtqt20u21/C8ViJ0GTTbyo7iwwge+M.
This key is not known by any other names
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '158.160.52.236' (ED25519) to the list of known hosts.
Welcome to Ubuntu 22.04.2 LTS (GNU/Linux 5.15.0-76-generic x86_64)
...
ubuntu@fhmujt8du6umb3fp85q1:~$ ping 8.8.8.8
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=61 time=19.4 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=61 time=19.1 ms
64 bytes from 8.8.8.8: icmp_seq=3 ttl=61 time=19.1 ms
^C
--- 8.8.8.8 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 19.114/19.209/19.382/0.122 ms
ubuntu@fhmujt8du6umb3fp85q1:~$ exit
logout
Connection to 158.160.52.236 closed.
```

Поскольку к инстансу из приватной подсети снаружи не попасть (нет публичного IP), то копируем приватный ключ на публичный инстанс и подключаемся с его помощью на приватный инстанс
```bash
$ scp ~/.ssh/id_ed25519 ubuntu@158.160.52.236:~/.ssh/id_ed25519
id_ed25519                                                                            100%  411    50.8KB/s   00:00
$ ssh ubuntu@158.160.52.236
Welcome to Ubuntu 22.04.2 LTS (GNU/Linux 5.15.0-76-generic x86_64)
...
ubuntu@fhmujt8du6umb3fp85q1:~$ ssh ubuntu@192.168.20.4
...
ubuntu@fhm66ggr0e0fhtcea9br:~$ ping 8.8.8.8
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=59 time=21.5 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=59 time=20.8 ms
64 bytes from 8.8.8.8: icmp_seq=3 ttl=59 time=20.9 ms
^C
--- 8.8.8.8 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 20.797/21.039/21.453/0.293 ms
```

Видим, что доступ в интернет с обоих машин есть
