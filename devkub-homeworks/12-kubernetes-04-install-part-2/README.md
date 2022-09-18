# 12.4. Развертывание кластера на собственных серверах, лекция 2
>Новые проекты пошли стабильным потоком. Каждый проект требует себе несколько кластеров: под тесты и продуктив. Делать все руками — не вариант, поэтому стоит автоматизировать подготовку новых кластеров.

## Задание 1: Подготовить инвентарь kubespray
>Новые тестовые кластеры требуют типичных простых настроек. Нужно подготовить инвентарь и проверить его работу. Требования к инвентарю:
>* подготовка работы кластера из 5 нод: 1 мастер и 4 рабочие ноды;
>* в качестве CRI — containerd;
>* запуск etcd производить на мастере.

## Ответ 1:

Уточнение задания на лекции: в качестве CRI - `docker`, доступ с локального компьютера в kubernates через `kubectl`

### Шаг 1. Создаём сервера

С помощью [terraform](./terraform) поднимаем необходимое количество инстансов на Yandex.Cloud
```bash
$ cd terraform
$ yc init
$ yc iam key create --service-account-name terraform-service-account --output key.json
$ terraform init
$ terraform validate
$ terraform apply -auto-approve
```

В итоге получаем сервера с адресами
```bash
$ yc compute instance list
+----------------------+-------+---------------+---------+---------------+-------------+
|          ID          | NAME  |    ZONE ID    | STATUS  |  EXTERNAL IP  | INTERNAL IP |
+----------------------+-------+---------------+---------+---------------+-------------+
| fhmbira3vhuifh2llo2n | cp1   | ru-central1-a | RUNNING | 51.250.10.22  | 10.0.0.34   |
| fhma2fuq5846llnugt3d | node1 | ru-central1-a | RUNNING | 51.250.82.9   | 10.0.0.8    |
| fhmhs3u94337hbtl67bs | node2 | ru-central1-a | RUNNING | 51.250.79.196 | 10.0.0.13   |
| fhmp3tkhvccemru70tgk | node3 | ru-central1-a | RUNNING | 51.250.83.86  | 10.0.0.20   |
| fhm31tt96s090c95iios | node4 | ru-central1-a | RUNNING | 51.250.78.236 | 10.0.0.23   |
+----------------------+-------+---------------+---------+---------------+-------------+
```


### Шаг 2. Подключаемся к мастер-ноде и устанавливаем зависимости

По публичному IP-адресу подключаемся к мастер-ноде, клонируем репозиторий kubespray и донастраиваепм ноду
```bash
$ ssh ubuntu@51.250.10.22
$ git clone https://github.com/kubernetes-sigs/kubespray
$ sudo apt-get update
$ sudo apt-get install -y pip
$ sudo pip3 install -r requirements.txt
```

Заодно поставим kubectl
```bash
$ sudo apt-get install -y apt-transport-https
$ curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
$ echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
$ sudo apt-get update
$ sudo apt-get install -y kubectl
```

А также копируем сюда приватный ключ, чтобы иметь доступ к остальным нодам
```bash
$ nano ~/.ssh/id_rsa
$ chmod 0600 ~/.ssh/id_rsa
```

### Шаг 3. Настраиваем конфигурацию kubespray



## ~Задание 2 (*): подготовить и проверить инвентарь для кластера в AWS~
>Часть новых проектов хотят запускать на мощностях AWS. Требования похожи:
>* разворачивать 5 нод: 1 мастер и 4 рабочие ноды;
>* работать должны на минимально допустимых EC2 — t3.small.
