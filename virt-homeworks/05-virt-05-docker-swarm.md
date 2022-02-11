# 5.5. Оркестрация кластером Docker контейнеров на примере Docker Swarm

## Задача 1

1. В чём отличие режимов работы сервисов в Docker Swarm кластере: replication и global?
   - В режиме global сервис будет установлен на каждую машину в кластере в одном экземляре (мониторинг, антивирус и т.п.). При добавлении новой машины в кластер она также получит данный сервис
   - В режиме replication в кластере будет требуемое количество экземляров сервиса. В том числе сервис может присутствовать на одной и той же машине в нескольких экземлярах сразу
2. Какой алгоритм выбора лидера используется в Docker Swarm кластере?
   - The Raft Consensus Algorithm, демонстрация работы [тут](http://thesecretlivesofdata.com/raft/)
3. Что такое Overlay Network?
   - Оверлейная сеть - это сеть, которая работает поверх другой сети. Примером может быть VPN

## Задача 2

Создать ваш первый Docker Swarm кластер в Яндекс.Облаке

**Ответ**

Скриншот из терминала (консоли), с выводом команды ``docker node ls``:

![Результат вывода команды docker node ls](05-virt-05-docker-swarm-assets/docker-node-ls.png)


## Задача 3

Создать ваш первый, готовый к боевой эксплуатации кластер мониторинга, состоящий из стека микросервисов.

**Ответ**

Скриншот из терминала (консоли), с выводом команды: ``docker service ls``:

![Результат вывода команды docker service ls](05-virt-05-docker-swarm-assets/docker-service-ls.png)


***Подробности выполнения задач 2 и 3***:

### Шаг 0. Подготовка окружения

В основном, это дублирование шагов из предыдущего домашнего задания по [5.4 Docker Compose](https://github.com/Roma-EDU/devops-netology/blob/master/virt-homeworks/05-virt-04-docker-compose.md)
1. Копирование приложенных ресурсов (папки ansible, packer и terraform) в шаренyую папку vagrant
2. Запуск виртуалки из прошлого задания (там уже установлены все необходимые пакеты).
3. Инициализация клиента Яндекс.Облака
   ```bash
   $ yc init
   Welcome! This command will take you through the configuration process.
   Pick desired action:
    [1] Re-initialize this profile 'default' with new settings
    [2] Create a new profile
   Please enter your numeric choice: 1
   Please go to https://oauth.yandex.ru/authorize?response_type=token&client_id=MY_CLIENT_ID in order to obtain OAuth token.
   
   Please enter OAuth token: [TOKEN_START*********************TOKEN_END] MY_API_TOKEN
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
4. Создание сети для работы packer и сборка образа, как в прошлом ДЗ, включая предварительное создание сети и её последующее удаление. В итоге получаем образ:
   ```bash
   ...
   ==> Builds finished. The artifacts of successful builds are:
   --> yandex: A disk image was created: centos-7-base (id: fd82134sp9upefm12mab) with family name centos
   $ yc compute image list
   +----------------------+---------------+--------+----------------------+--------+
   |          ID          |     NAME      | FAMILY |     PRODUCT IDS      | STATUS |
   +----------------------+---------------+--------+----------------------+--------+
   | fd82134sp9upefm12mab | centos-7-base | centos | f2e40ohi7d1hori8m71b | READY  |
   +----------------------+---------------+--------+----------------------+--------+
   ```
   
### Шаг 1. Подготовка файлов terrraform

Переходим в рабочую папку terrraform и формируем в ней key.json (сервис-аккаунт уже создан в облаке и имеет необходимые права)
```bash
$ cd /vagrant/05-virt-05-docker-swarm/terraform/
$ yc iam key create --service-account-name netology-service --output key.json
id: ajehitf7492ipfbslv9q
service_account_id: ajemq8n94gv1mgig7s48
created_at: "2022-02-10T23:34:54.265762594Z"
key_algorithm: RSA_2048
```
А также заполняем файлик ``variables.tf`` правильными идентификаторами папочек и образа
```tf
# ID своего облака
# https://console.cloud.yandex.ru/cloud?section=overview
variable "yandex_cloud_id" {
  default = "b1gjn3v7sno758hjjba0"
}

# Folder своего облака
# https://console.cloud.yandex.ru/cloud?section=overview
variable "yandex_folder_id" {
  default = "b1gr1vdb5g3ktr8v0877"
}

# ID своего образа, можно узнать с помощью команды yc compute image list
variable "centos-7-base" {
  default = "fd82134sp9upefm12mab"
}
```

### Шаг 2. Подготовка terrraform

Обновляем пакеты, инициализируем терраформ с принудительной перечиткой (иначе может выдавать ошибку на валидации). Затем на всякий случай валидируем файл конфигурации и планируем исполнение

```bash
$ sudo apt-get update
Hit:1 http://archive.ubuntu.com/ubuntu focal InRelease
...
Fetched 7541 kB in 6s (1340 kB/s)
Reading package lists... Done

$ terraform init -upgrade

Initializing the backend...

Initializing provider plugins...
- Finding latest version of yandex-cloud/yandex...
...

$ terraform validate
Success! The configuration is valid.

$ terraform plan

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the
following symbols:
  + create
...
```

### Шаг 3. Разворачивание всего кластера с помощью terrraform

Вызываем всего лишь одну команду (и потом ждём некоторое время, условные минут 10 в общей сложности)
```bash
$ terraform apply -auto-approve
...
null_resource.monitoring: Still creating... [30s elapsed]
null_resource.monitoring: Creation complete after 30s [id=578052530411102225]

Apply complete! Resources: 13 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_node01 = "62.84.125.80"
external_ip_address_node02 = "62.84.126.34"
external_ip_address_node03 = "62.84.115.233"
external_ip_address_node04 = "62.84.127.5"
external_ip_address_node05 = "62.84.124.53"
external_ip_address_node06 = "62.84.126.55"
internal_ip_address_node01 = "192.168.101.11"
internal_ip_address_node02 = "192.168.101.12"
internal_ip_address_node03 = "192.168.101.13"
internal_ip_address_node04 = "192.168.101.14"
internal_ip_address_node05 = "192.168.101.15"
internal_ip_address_node06 = "192.168.101.16"

```

***Note***: Вопреки флажку -auto-approve, когда мы дошли до шага установки с помощью ansible необходимых сервисов, пришлось 6 раз (по количеству нод) вводить согласие на заливку
```bash
The authenticity of host '62.84.115.233 (62.84.115.233)' can't be established.
ECDSA key fingerprint is SHA256:zJtzaRBTEuGArwvCCMXBBqT2WoMwGHTEhLq2K4DIu5Y.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
```

### Шаг 4. Проверяем, что всё работает

Подключаемся к любой ноде из развёрнутого кластера и проверяем, что все сервисы запущены в нужном количестве
```bash
$ ssh centos@62.84.125.80
[centos@node01 ~]$ sudo -i
[root@node01 ~]# docker node ls
ID                            HOSTNAME             STATUS    AVAILABILITY   MANAGER STATUS   ENGINE VERSION
oyscifwbcg54plon10t1mzrb4 *   node01.netology.yc   Ready     Active         Leader           20.10.12
ze3al2iar6tkc81t2dliike3h     node02.netology.yc   Ready     Active         Reachable        20.10.12
sx3eslmmd6ahzhaiyzt2umu8y     node03.netology.yc   Ready     Active         Reachable        20.10.12
cqdj66rhpzn6oy3nt20v4q67v     node04.netology.yc   Ready     Active                          20.10.12
hnspo8is37iqv5rz6mybjbjgc     node05.netology.yc   Ready     Active                          20.10.12
kkgi83v6ofse3f3oclgufikfz     node06.netology.yc   Ready     Active                          20.10.12

[root@node01 ~]# docker service ls
ID             NAME                                MODE         REPLICAS   IMAGE                                          PORTS
wvsi19ev0q0d   swarm_monitoring_alertmanager       replicated   1/1        stefanprodan/swarmprom-alertmanager:v0.14.0   
v4jnhq53ajff   swarm_monitoring_caddy              replicated   1/1        stefanprodan/caddy:latest                      *:3000->3000/tcp, *:9090->9090/tcp, *:9093-9094->9093-9094/tcp
q2fs9j020czk   swarm_monitoring_cadvisor           global       6/6        google/cadvisor:latest

yqgs9nor6yzu   swarm_monitoring_dockerd-exporter   global       6/6        stefanprodan/caddy:latest

ozmkauozqha1   swarm_monitoring_grafana            replicated   1/1        stefanprodan/swarmprom-grafana:5.3.4

s3c819m0b8xf   swarm_monitoring_node-exporter      global       6/6        stefanprodan/swarmprom-node-exporter:v0.16.0

wqjoi351v3rq   swarm_monitoring_prometheus         replicated   1/1        stefanprodan/swarmprom-prometheus:v2.5.0

gnz0z16wh0zr   swarm_monitoring_unsee              replicated   1/1        cloudflare/unsee:v0.8.0

[root@node01 ~]# exit
logout
[centos@node01 ~]$ exit
logout
Connection to 62.84.125.80 closed.
```

### Шаг 5*. Останавливаем работу облака

Чтобы не тратить деньги, останавливаем всё

```bash
$ terraform destroy -auto-approve
yandex_vpc_network.default: Refreshing state... [id=enpv2l2vvokkce5j02ma]
yandex_vpc_subnet.default: Refreshing state... [id=e9bdlks4frcrmk7mrspi]
...
yandex_vpc_network.default: Destroying... [id=enpv2l2vvokkce5j02ma]
yandex_vpc_network.default: Destruction complete after 0s

Destroy complete! Resources: 13 destroyed.
```
А также не забываем зайти в веб-консоль и удалить оттуда сервис-аккаунт и образ centos.

## Задача 4 (*)

Выполнить на лидере Docker Swarm кластера команду (указанную ниже) и дать письменное описание её функционала, что она делает и зачем она нужна:
```
# см.документацию: https://docs.docker.com/engine/swarm/swarm_manager_locking/
docker swarm update --autolock=true
```
