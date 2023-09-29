# Создание Kubernetes кластера

На этом этапе будем создать Kubernetes кластер с доступом к ресурсам из Интернета.

## 0. Подготовка окружения

Разворачивать кластер будем с помощью [https://github.com/kubernetes-sigs/kubespray](https://github.com/kubernetes-sigs/kubespray), поэтому нам понадобится его фиксированная копия (чтобы изменения в оригинале не поломали в какой-то момент нам весь процесс). 
Положим копию репозитория себе в папку [kubespray](https://github.com/Roma-EDU/diploma-infrastructure/tree/master/kubespray) и установим необходимые для него программы:
```bash
$ cd /vagrant/kubespray/
$ sudo apt-get update
$ sudo apt-get install -y pip
$ sudo pip3 install -r requirements.txt
```

Заодно поставим kubectl и kubeadm версии 1.28.2 (такая же используется в kubespray) и зафиксируем их от обновления. Подробная инструкция на сайте [kubernetes.io](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)
```bash
$ sudo apt-get install -y apt-transport-https ca-certificates curl
$ curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
$ echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
$ sudo apt-get update
$ sudo apt-get install -y kubelet kubeadm kubectl
$ sudo apt-mark hold kubelet kubeadm kubectl
```
