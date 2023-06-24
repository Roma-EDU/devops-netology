# 13.3. Как работает сеть в K8s

>## Цель задания
>
>Настроить сетевую политику доступа к подам.
>
>## Чеклист готовности к домашнему заданию
>
>1. Кластер K8s с установленным сетевым плагином Calico.
>
>## Инструменты и дополнительные материалы, которые пригодятся для выполнения задания
>
>1. [Документация Calico](https://www.tigera.io/project-calico/).
>2. [Network Policy](https://kubernetes.io/docs/concepts/services-networking/network-policies/).
>3. [About Network Policy](https://docs.projectcalico.org/about/about-network-policy).

Поднимем локальный кластер с помощью `minikube`

### Шаг 1. Подготовим виртуальную машину 

Создадим Vagrantfile для поднятия виртуальной машины с 2 CPU и 3 Гб оперативки (для самого minikube нужно от 2 Гб оперативки + 1 Гб для хоста) 
```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"
  config.vm.provider "virtualbox" do |vb|
    vb.name = "Minikube"
    vb.memory = 3072
    vb.cpus = 2
  end
end
```
И запустим его с помощью терминала
```
> vagrant up && vagrant ssh
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Checking if box 'bento/ubuntu-22.04' version '202303.13.0' is up to date...
==> default: There was a problem while downloading the metadata for your box
...
Welcome to Ubuntu 22.04.2 LTS (GNU/Linux 5.15.0-67-generic x86_64)
...
Last login: Sat Jun 24 11:36:58 2023 from 10.0.2.2
vagrant@vagrant:~$
```

### Шаг 2. Установим docker (понадобится для запуска minikube)

Установим docker и docker-compose согласно [документации](https://docs.docker.com/engine/install/ubuntu/)
```bash
$ sudo apt-get update
$ sudo apt-get install ca-certificates curl gnupg

$ sudo install -m 0755 -d /etc/apt/keyrings
$ curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
$ sudo chmod a+r /etc/apt/keyrings/docker.gpg

$ echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
$ sudo apt-get update
$ sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

$ sudo apt-get update
$ sudo apt-get install docker-compose-plugin
```
И проверим, что они работают
```bash
$ sudo docker run hello-world

Hello from Docker!
This message shows that your installation appears to be working correctly.
...
$ docker compose version
Docker Compose version v2.18.1
```

### Шаг 3. Установим minikube с сетевым плагином Calico

Установим minikube согласно [документации](https://minikube.sigs.k8s.io/docs/start/)
```bash
$ curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb
$ sudo dpkg -i minikube_latest_amd64.deb
```

Разрешим использовать docker от текущего пользователя и настроим его использование по умолчанию согласно [документации](https://minikube.sigs.k8s.io/docs/drivers/docker/)
```bash
$ sudo groupadd docker
$ sudo usermod -aG docker $USER
$ minikube config set driver docker
```

Запустим minikube с сетевым плагином Calico
```bash
$ minikube start --network-plugin=cni --cni=calico
😄  minikube v1.30.1 on Ubuntu 22.04 (vbox/amd64)
✨  Using the docker driver based on existing profile

🧯  The requested memory allocation of 2200MiB does not leave room for system overhead (total system memory: 2980MiB). You may face stability issues.
💡  Suggestion: Start minikube with less memory allocated: 'minikube start --memory=2200mb'
...
🐳  Preparing Kubernetes v1.26.3 on Docker 23.0.2 ...
🔗  Configuring Calico (Container Networking Interface) ...
🔎  Verifying Kubernetes components...
    ▪ Using image gcr.io/k8s-minikube/storage-provisioner:v5
🌟  Enabled addons: storage-provisioner, default-storageclass
💡  kubectl not found. If you need it, try: 'minikube kubectl -- get pods -A'
🏄  Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
```


## Задание 1. Создать сетевую политику или несколько политик для обеспечения доступа

>1. Создать deployment'ы приложений frontend, backend и cache и соответсвующие сервисы.
>2. В качестве образа использовать network-multitool.
>3. Разместить поды в namespace App.
>4. Создать политики, чтобы обеспечить доступ frontend -> backend -> cache. Другие виды подключений должны быть запрещены.
>5. Продемонстрировать, что трафик разрешён и запрещён.

### Шаг 1. Подготовим манифесты с необходимыми Deployment и Service

1. Для каждого приложения создадим отдельный deployment и соответствующий ему сервис [frontend](./frontend.yml), [backend](./backend.yml) и [cache](cache.yml). В качестве тестового образа используем последнуюю версию network-multitool (см. в манифесте `image: praqma/network-multitool`)
2. Создадим нужный нам namespace `app` и переключимся в него
   ```bash
   $ minikube kubectl -- create namespace app
   namespace/app created
   $ minikube kubectl -- config set-context --current --namespace=app
   Context "minikube" modified.
   ```
3. Перейдём в папку с манифестами и применим их
   ```bash
   $ cd /vagrant/13-kuber-homeworks-03-network/
   $ minikube kubectl -- apply -f cache.yml
   deployment.apps/cache created
   service/cache created
   $ minikube kubectl -- apply -f backend.yml
   deployment.apps/backend created
   service/backend created
   $ minikube kubectl -- apply -f frontend.yml
   deployment.apps/frontend created
   service/frontend created
   ```
4. Проверим поды и сервисы
   ```bash
   $ minikube kubectl -- get pods -A
   NAMESPACE     NAME                                      READY   STATUS    RESTARTS      AGE
   app           backend-686f89dbc-mrllj                   1/1     Running   1 (21m ago)   89m
   app           cache-56498cc6c5-p2wch                    1/1     Running   1 (21m ago)   85m
   app           frontend-7db459d997-vqdq9                 1/1     Running   1 (21m ago)   142m
   kube-system   calico-kube-controllers-7bdbfc669-28h8n   1/1     Running   2 (21m ago)   9h
   kube-system   calico-node-fmtzm                         1/1     Running   1 (21m ago)   9h
   kube-system   coredns-787d4945fb-779wq                  1/1     Running   3 (21m ago)   9h
   kube-system   etcd-minikube                             1/1     Running   1 (21m ago)   9h
   kube-system   kube-apiserver-minikube                   1/1     Running   1 (21m ago)   9h
   kube-system   kube-controller-manager-minikube          1/1     Running   1 (21m ago)   9h
   kube-system   kube-proxy-dvpv8                          1/1     Running   1 (21m ago)   9h
   kube-system   kube-scheduler-minikube                   1/1     Running   1 (21m ago)   9h
   kube-system   storage-provisioner                       1/1     Running   3 (19m ago)   9h

   $ minikube kubectl -- get services -A
   NAMESPACE     NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                  AGE
   app           backend      ClusterIP   10.96.99.196     <none>        80/TCP                   143m
   app           cache        ClusterIP   10.101.79.186    <none>        80/TCP                   143m
   app           frontend     ClusterIP   10.98.145.215    <none>        80/TCP                   144m
   default       kubernetes   ClusterIP   10.96.0.1        <none>        443/TCP                  9h
   kube-system   kube-dns     ClusterIP   10.96.0.10       <none>        53/UDP,53/TCP,9153/TCP   9h
   ```

### Шаг 2. Добавим network-policy

1. Создадим манифест [network-policy](./network-policy.yml), запрещающий все [входящие] подключения, кроме frontent->backend и backend->cache
2. Применим его
   ```bash
   $ minikube kubectl -- apply -f network-policy.yml
   networkpolicy.networking.k8s.io/deny-all created
   networkpolicy.networking.k8s.io/allow-backend-to-cache created
   networkpolicy.networking.k8s.io/allow-frontend-to-backend created
   ```
3. Проверим, что доступы работают. Для этого зайдём в pod backend'а и попробуем с помощью curl достучаться к сервисам cache и frontend
   ```bash
   $ minikube kubectl -- exec backend-686f89dbc-mrllj -it -- /bin/sh
   / # curl cache.app.svc.cluster.local
   Praqma Network MultiTool (with NGINX) - cache-56498cc6c5-p2wch - 10.244.120.76 - HTTP: 80 , HTTPS: 443
   <br>
   ...
   / # curl frontend.app.svc.cluster.local
   <ответа нет>
   ^C
   ```

Заметки:
* Имя сервиса формируется так: `<service-name>.<namespace>.svc.cluster.local:<service-port>`
* Выйти из консоли внутри пода `Ctrl+P`, `Ctrl+Q`
