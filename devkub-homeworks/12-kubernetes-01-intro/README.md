# 12.1. Компоненты Kubernetes

> Вы DevOps инженер в крупной компании с большим парком сервисов. Ваша задача — разворачивать эти продукты в корпоративном кластере. 

## Задача 1: Установить Minikube

> Для экспериментов и валидации ваших решений вам нужно подготовить тестовую среду для работы с Kubernetes. Оптимальное решение — развернуть на рабочей машине Minikube.
>
>### Как поставить на AWS:
>- создать EC2 виртуальную машину (Ubuntu Server 20.04 LTS (HVM), SSD Volume Type) с типом **t3.small**. Для работы потребуется настроить Security Group для доступа по ssh. Не забудьте указать keypair, он потребуется для подключения.
>- подключитесь к серверу по ssh (ssh ubuntu@<ipv4_public_ip> -i <keypair>.pem)
>- установите миникуб и докер следующими командами:
>  - curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
>  - chmod +x ./kubectl
>  - sudo mv ./kubectl /usr/local/bin/kubectl
>  - sudo apt-get update && sudo apt-get install docker.io conntrack -y
>  - curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && chmod +x minikube && sudo mv minikube /usr/local/bin/
>- проверить версию можно командой minikube version
>- переключаемся на root и запускаем миникуб: minikube start --vm-driver=none
>- после запуска стоит проверить статус: minikube status
>- запущенные служебные компоненты можно увидеть командой: kubectl get pods --namespace=kube-system
>
>### Для сброса кластера стоит удалить кластер и создать заново:
>- minikube delete
>- minikube start --vm-driver=none
>
>Возможно, для повторного запуска потребуется выполнить команду: sudo sysctl fs.protected_regular=0
>
>Инструкция по установке Minikube - [ссылка](https://kubernetes.io/ru/docs/tasks/tools/install-minikube/)
>
>**Важно**: t3.small не входит во free tier, следите за бюджетом аккаунта и удаляйте виртуалку.

**Ответ**  

### Шаг 1. Установка minikube на Yandex.Cloud
  
Запускаем инстанс Yandex.Cloud (2 ядра, 2 или 4 ГБ) из образа с установленным docker (Container Optimized Image 2.3.10), подключаемся к нему по ssh и устанавливаем minkube
```bash
$ curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 26.1M  100 26.1M    0     0  25.2M      0  0:00:01  0:00:01 --:--:-- 25.2M

$ sudo dpkg -i minikube_latest_amd64.deb
Selecting previously unselected package minikube.
(Reading database ... 75803 files and directories currently installed.)
Preparing to unpack minikube_latest_amd64.deb ...
Unpacking minikube (1.27.0-0) ...
Setting up minikube (1.27.0-0) ...

$ minikube start
😄  minikube v1.27.0 on Ubuntu 20.04 (amd64)
❗  Kubernetes 1.25.0 has a known issue with resolv.conf. minikube is using a workaround that should work for most use cases.
❗  For more information, see: https://github.com/kubernetes/kubernetes/issues/112135
✨  Automatically selected the docker driver. Other choices: none, ssh
📌  Using Docker driver with root privileges
👍  Starting control plane node minikube in cluster minikube
🚜  Pulling base image ...
    > gcr.io/k8s-minikube/kicbase:  0 B [________________________] ?% ? p/s 36s
🔥  Creating docker container (CPUs=2, Memory=2200MB) ...
🐳  Preparing Kubernetes v1.25.0 on Docker 20.10.17 ...
    ▪ Generating certificates and keys ...
    ▪ Booting up control plane ...
    ▪ Configuring RBAC rules ...
🔎  Verifying Kubernetes components...
    ▪ Using image gcr.io/k8s-minikube/storage-provisioner:v5
🌟  Enabled addons: storage-provisioner, default-storageclass
💡  kubectl not found. If you need it, try: 'minikube kubectl -- get pods -A'
🏄  Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
  
$ minikube status
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

## Задача 2: Запуск Hello World
>После установки Minikube требуется его проверить. Для этого подойдет стандартное приложение hello world. А для доступа к нему потребуется ingress.
>
>- развернуть через Minikube тестовое приложение по [туториалу](https://kubernetes.io/ru/docs/tutorials/hello-minikube/#%D1%81%D0%BE%D0%B7%D0%B4%D0%B0%D0%BD%D0%B8%D0%B5-%D0%BA%D0%BB%D0%B0%D1%81%D1%82%D0%B5%D1%80%D0%B0-minikube)
>- установить аддоны ingress и dashboard

**Ответ**  

### Шаг 0. Установим kubectl

```bash
$ curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 42.9M  100 42.9M    0     0  65.0M      0 --:--:-- --:--:-- --:--:-- 65.0M
$ sudo chmod +x ./kubectl
$ sudo mv ./kubectl /usr/local/bin/kubectl
$ kubectl get nodes
NAME       STATUS   ROLES           AGE    VERSION
minikube   Ready    control-plane   107s   v1.25.0
```

### Шаг 1. Установим тестовое приложение

```bash
$ kubectl create deployment hello-node --image=k8s.gcr.io/echoserver:1.4
deployment.apps/hello-node created
$ kubectl get pods
NAME                         READY   STATUS    RESTARTS   AGE
hello-node-697897c86-qhvn2   1/1     Running   0          28s
$ kubectl get deployments
NAME         READY   UP-TO-DATE   AVAILABLE   AGE
hello-node   1/1     1            1           31s
```

### Шаг 2. Установим дополнения

```bash
$ minikube addons enable ingress
💡  ingress is an addon maintained by Kubernetes. For any concerns contact minikube on GitHub.
You can view the list of minikube maintainers at: https://github.com/kubernetes/minikube/blob/master/OWNERS
    ▪ Using image k8s.gcr.io/ingress-nginx/controller:v1.2.1
    ▪ Using image k8s.gcr.io/ingress-nginx/kube-webhook-certgen:v1.1.1
    ▪ Using image k8s.gcr.io/ingress-nginx/kube-webhook-certgen:v1.1.1
🔎  Verifying ingress addon...
🌟  The 'ingress' addon is enabled
$ minikube addons enable dashboard
💡  dashboard is an addon maintained by Kubernetes. For any concerns contact minikube on GitHub.
You can view the list of minikube maintainers at: https://github.com/kubernetes/minikube/blob/master/OWNERS
    ▪ Using image docker.io/kubernetesui/dashboard:v2.6.0
    ▪ Using image docker.io/kubernetesui/metrics-scraper:v1.0.8
💡  Some dashboard features require the metrics-server addon. To enable all features please run:

        minikube addons enable metrics-server


🌟  The 'dashboard' addon is enabled
```

  
## Задача 3: Установить kubectl

>Подготовить рабочую машину для управления корпоративным кластером. Установить клиентское приложение kubectl.
>- подключиться к minikube 
>- проверить работу приложения из задания 2, запустив port-forward до кластера

**Ответ**  

### Шаг 0. Установка kubectl

Уже сделали в задаче 2

### Шаг 1. Запустим port-forward

```bash
$ kubectl port-forward deployment/hello-node 8080:8080
Forwarding from 127.0.0.1:8080 -> 8080
Forwarding from [::1]:8080 -> 8080
Handling connection for 8080

```

И проверим в другом терминале

```bash
curl 127.0.0.1:8080
CLIENT VALUES:
client_address=127.0.0.1
command=GET
real path=/
query=nil
request_version=1.1
request_uri=http://127.0.0.1:8080/

SERVER VALUES:
server_version=nginx: 1.10.0 - lua: 10001

HEADERS RECEIVED:
accept=*/*
host=127.0.0.1:8080
user-agent=curl/7.68.0
BODY:
-no body in request-
```


## ~Задача 4 (*): собрать через ansible (необязательное)~

>Профессионалы не делают одну и ту же задачу два раза. Давайте закрепим полученные навыки, автоматизировав выполнение заданий  ansible-скриптами. При выполнении задания обратите внимание на доступные модули для k8s под ansible.
> - собрать роль для установки minikube на aws сервисе (с установкой ingress)
> - собрать роль для запуска в кластере hello world
  
