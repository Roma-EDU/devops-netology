# 5.4. Оркестрация группой Docker контейнеров на примере Docker Compose

## Задача 1

Создать собственный образ операционной системы с помощью Packer.

**Ответ**

<p align="center">
  <img width="1200" height="600" src="./05-virt-04-docker-compose-assets/Disk-image-from-packer.png">
</p>

### Шаг 0: Подготовка окружения
1. Запускаем виртуалку на Linux
   ```rust
   Vagrant.configure("2") do |config|
     config.vm.box = "ubuntu/focal64"
     config.vm.provider "virtualbox" do |vb|
       vb.name = "Main"
       vb.memory = "2048"
	   vb.cpus = 2
     end
   end
   ```
2. Создаём шаренную папку 05-virt-04-docker-compose и копируем в неё ресурсы (файлы для packer, terraform, ansible)
3. Регистрируемся на Yandex.Cloud и используем промокод
4. Удаляем автосозданные сети и подсети из папки ``default``, создаём собственную ``netology``

### Шаг 1: Установка клиента Yandex.Cloud
```bash
$ curl https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  9739  100  9739    0     0  77912      0 --:--:-- --:--:-- --:--:-- 77912
Downloading yc 0.87.0
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 81.2M  100 81.2M    0     0  4419k      0  0:00:18  0:00:18 --:--:-- 4287k
Yandex.Cloud CLI 0.87.0 linux/amd64

yc PATH has been added to your '/home/vagrant/.bashrc' profile
yc bash completion has been added to your '/home/vagrant/.bashrc' profile.
Now we have zsh completion. Type "echo 'source /home/vagrant/yandex-cloud/completion.zsh.inc' >>  ~/.zshrc" to install itTo complete installation, start a new shell (exec -l $SHELL) or type 'source "/home/vagrant/.bashrc"' in the current one

$ echo 'source /home/vagrant/yandex-cloud/completion.zsh.inc' >>  ~/.zshrc
$ source "/home/vagrant/.bashrc"
$ yc --version
Yandex.Cloud CLI 0.87.0 linux/amd64
```
### Шаг 2: Инициализация и первичная настройка Yandex.Cloud
1. Вводим команду ``yc init`` и переходим по указанной ссылке
2. Получаем токен и вводим его
3. Выбираем созданную ранее папку ``netology``
4. Выбираем зоную доступа ``ru-central1-a`` (т.к. она используется в конфигах далее)

```bash
$ yc init
Welcome! This command will take you through the configuration process.
Please go to https://oauth.yandex.ru/authorize?response_type=token&client_id=MY_ID in order to obtain OAuth token.

Please enter OAuth token: MY_API_TOKEN
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
### Шаг 3: Создаём сеть и подсеть для работы packer
```bash
$ yc vpc network create --name net --labels my-label=netology --description "my first network via yc"
id: enpbf7hk34227thef30v
folder_id: b1gr1vdb5g3ktr8v0877
created_at: "2022-02-06T12:54:31Z"
name: net
description: my first network via yc
labels:
  my-label: netology

$ yc vpc subnet create --name my-subnet-a --zone ru-central1-a --range 10.1.2.0/24 --network-name net --description "my first subnet via yc"
id: e9b7k86eethgliqmku5r
folder_id: b1gr1vdb5g3ktr8v0877
created_at: "2022-02-06T12:55:21Z"
name: my-subnet-a
description: my first subnet via yc
network_id: enpbf7hk34227thef30v
zone_id: ru-central1-a
v4_cidr_blocks:
- 10.1.2.0/24
```
### Шаг 4: Устанавливаем сам packer
Переходим на сайт разработчика [Packer.io](https://www.packer.io/downloads) и следуем инструкции для Ubuntu
```bash
$ curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
OK
$ sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
Hit:1 http://archive.ubuntu.com/ubuntu focal InRelease
...
Get:40 http://archive.ubuntu.com/ubuntu focal-backports/multiverse amd64 c-n-f Metadata [116 B]
Fetched 20.9 MB in 24s (885 kB/s)
Reading package lists... Done

$ sudo apt-get update && sudo apt-get install packer
Hit:1 http://security.ubuntu.com/ubuntu focal-security InRelease
...
Setting up packer (1.7.10) ...
$ packer --version
1.7.10
```
### Шаг 5: Редактируем конфигурационный файл для создания образа
Проверяем, что в файле ``/packer/centos-7-base.json`` указаный правильные ``folder_id``, ``subnet_id`` (см. шаг 3) и ``token``
```json
{
  "builders": [
    {
      "disk_type": "network-nvme",
      "folder_id": "b1gr1vdb5g3ktr8v0877",
      "image_description": "by packer",
      "image_family": "centos",
      "image_name": "centos-7-base",
      "source_image_family": "centos-7",
      "ssh_username": "centos",
      "subnet_id": "e9b7k86eethgliqmku5r",
      "token": "MY_API_TOKEN",
      "type": "yandex",
      "use_ipv4_nat": true,
      "zone": "ru-central1-a"
    }
  ],
  "provisioners": [
    {
      "inline": [
        "sudo yum -y update",
        "sudo yum -y install bridge-utils bind-utils iptables curl net-tools tcpdump rsync telnet openssh-server"
      ],
      "type": "shell"
    }
  ]
}
```
### Шаг 6: Собираем образ
Переходим в папку с конфигурационным файлом packer'а для создания образа, валидируем и собираем
```bash
$ cd packer
$ packer validate centos-7-base.json
The configuration is valid.
$ packer build centos-7-base.json
yandex: output will be in this color.

==> yandex: Creating temporary RSA SSH key for instance...
==> yandex: Using as source image: fd8aqitd4vl5950ihohp (name: "centos-7-v20220131", family: "centos-7")
==> yandex: Use provided subnet id e9b7k86eethgliqmku5r
==> yandex: Creating disk...
...
==> yandex: Success image create...
==> yandex: Destroying boot disk...
    yandex: Disk has been deleted!
Build 'yandex' finished after 2 minutes 6 seconds.

==> Wait completed after 2 minutes 6 seconds

==> Builds finished. The artifacts of successful builds are:
--> yandex: A disk image was created: centos-7-base (id: fd889r4a79btes3ngeue) with family name centos
$ yc compute image list
+----------------------+---------------+--------+----------------------+--------+
|          ID          |     NAME      | FAMILY |     PRODUCT IDS      | STATUS |
+----------------------+---------------+--------+----------------------+--------+
| fd889r4a79btes3ngeue | centos-7-base | centos | f2eacrudv331nbat9ehb | READY  |
+----------------------+---------------+--------+----------------------+--------+
```

## Задача 2

Создать вашу первую виртуальную машину в Яндекс.Облаке.

## Задача 3

Создать ваш первый готовый к боевой эксплуатации компонент мониторинга, состоящий из стека микросервисов.



## Задача 4 (*)

Создать вторую ВМ и подключить её к мониторингу развёрнутому на первом сервере.

Для получения зачета, вам необходимо предоставить:
- Скриншот из Grafana, на котором будут отображаться метрики добавленного вами сервера.
