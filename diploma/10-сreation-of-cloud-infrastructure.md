# Создание облачной инфраструктуры

* Дипломный проект будет выполняться с помощью виртуальной машины на актуальной в данный момент Ubuntu 22.04.3 LTS, запущенной с помощью `vagrant`. 
* Содержимое вывода результата команд в некоторых случаях будет сокращаться с помощью `...` на отдельной строке, чтобы не отвлекать от основных действий

## 1. Подготавливаем рабочего окружения

### 1.1. Создаём виртуальную машину

Содержимое Vagrantfile:
```ruby
# -*- mode: ruby -*-
Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"
  config.vm.network "forwarded_port", guest: 8080, host: 8080
  config.vm.provider "virtualbox" do |vb|
    vb.name = "Diploma"
    vb.memory = 3072
    vb.cpus = 2
  end
end
```

Запуск и подключение к виртуальной машине:

```bat
> vagrant up && vagrant ssh
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Importing base box 'bento/ubuntu-22.04'...
==> default: Matching MAC address for NAT networking...
...
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-83-generic x86_64)
```

### 1.2. Устанавливаем Terraform

Согласно [инструкции](https://cloud.yandex.ru/docs/tutorials/infrastructure-management/terraform-quickstart) скачиваем с зеркала 
подходящую версию terraform (актуальная на сегодня terraform_1.5.7_linux_amd64.zip), распаковываем, копируем в папку "с программами"
и прописываем путь к нему.
```bash
$ sudo cp /vagrant/terraform /opt/
$ export PATH=$PATH:/opt/
$ terraform --version
Terraform v1.5.7
on linux_amd64
```

### 1.3. Устанавливаем Yandex Cloud CLI

```bash
$ curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
Downloading yc 0.110.0
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  108M  100  108M    0     0  10.2M      0  0:00:10  0:00:10 --:--:-- 10.5M
Yandex Cloud CLI 0.110.0 linux/amd64

yc PATH has been added to your '/home/vagrant/.bashrc' profile
yc bash completion has been added to your '/home/vagrant/.bashrc' profile.
Now we have zsh completion. Type "echo 'source /home/vagrant/yandex-cloud/completion.zsh.inc' >>  ~/.zshrc" to install it
To complete installation, start a new shell (exec -l $SHELL) or type 'source "/home/vagrant/.bashrc"' in the current one
$ echo 'source /home/vagrant/yandex-cloud/completion.zsh.inc' >>  ~/.zshrc
$ source "/home/vagrant/.bashrc"
$ yc --version
Yandex Cloud CLI 0.110.0 linux/amd64
```

### 1.4. Конфигурируем Yandex Cloud CLI

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
$  yc iam key create --service-account-id aje16dilsetnl7cjm5na --output /vagrant/secrets/key.json
id: aje38rabdn1ju4314q8d
service_account_id: aje16dilsetnl7cjm5na
created_at: "2023-09-19T21:04:17.994621273Z"
key_algorithm: RSA_2048
```
