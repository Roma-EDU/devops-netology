# 13.3. Как работает сеть в K8s

>### Цель задания
>
>Настроить сетевую политику доступа к подам.
>
>### Чеклист готовности к домашнему заданию
>
>1. Кластер K8s с установленным сетевым плагином Calico.
>
>### Инструменты и дополнительные материалы, которые пригодятся для выполнения задания
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


### Задание 1. Создать сетевую политику или несколько политик для обеспечения доступа

>1. Создать deployment'ы приложений frontend, backend и cache и соответсвующие сервисы.
>2. В качестве образа использовать network-multitool.
>3. Разместить поды в namespace App.
>4. Создать политики, чтобы обеспечить доступ frontend -> backend -> cache. Другие виды подключений должны быть запрещены.
>5. Продемонстрировать, что трафик разрешён и запрещён.

