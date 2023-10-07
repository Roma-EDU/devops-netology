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

И создадим пустой kube-config, в который позже будет записана конфигурация для подключения к развёрнутому кластеру
```bash
$ mkdir -p $HOME/.kube
$ touch $HOME/.kube/config
$ sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

## 1. Подготовка виртуальных машин

Согласно требованиям заполняем конфигурацию для terraform - папка [infrastructure](https://github.com/Roma-EDU/diploma-infrastructure/tree/master/infrastructure) (в основном файл main.tf, но и другие тоже нужны)

## 2. Подготовка ansible конфигурации

Переходим в папку со скачанным репозиторием kubespray, копируем оттуда файл `k8s-cluster.yml` 
```bash
$ cd /vagrant/kubespray
$ cp inventory/sample/group_vars/k8s_cluster/k8s-cluster.yml ../automation/k8s-cluster.yml
```
и настраиваем копию согласно нашим пожеланиям, а именно меняем/раскомментируем параметры:
* используем docker `container_manager: docker`
* понадобится локальная копию конфига: `kubeconfig_localhost: true`
* понадобится подключение снаружи: `supplementary_addresses_in_ssl_keys: [MASTER_PUBLIC_IPS_TO_REPLACE]` (IP адрес будет подставлен позже)

Кроме того, нам понадобится корректное формирование `hosts.yaml`, поэтому также копируем файл `inventory.py`
```bash
$ cp contrib/inventory_builder/inventory.py ../automation/inventory.py
$ cp contrib/inventory_builder/requirements.txt ../automation/requirements.txt
```
в котором сделаем несколько небольших правок
* не разворачиваем поды на мастер-ноды
* etcd находится только на мастер-нодах
* корректно прописываются ip-адреса (ansible_host, ip, access_ip)
* добавляем указание пользователя ansible_user (через переменную ANSIBLE_USER)
Итоговый файл [inventory.py](https://github.com/Roma-EDU/diploma-infrastructure/blob/master/automation/inventory.py)

А ещё возможно понадобится заменить симлинк `kubespray/library/kube.py` на сам полноценный файл `kubespray/plugins/modules/kube.py`

## 3. Автоматизируем процесс разворачивания кластера

Кластер может быть большим, копирование каждый раз названий нод, ip-адресов и т.д. может привести к ошибкам, поэтому пишем (долго и мучительно) несколько скриптов, которые помогут нам развернуть кластер в одну команду [build.sh](https://github.com/Roma-EDU/diploma-infrastructure/blob/master/build.sh)
Основные моменты:
1. Поднятие инфраструктуры с помощью terraform (`terraform apply -auto-approve`)
2. Получение от него информации, какие в итоге ноды были подняты и по каким адресам доступны (`terraform output -json`)
3. Формирование и исполнение команды для генерации hosts.yaml (`GENERATE_CMD`)
4. Формирование кластера с подстановкой актуальных значений (`hosts.yaml` и `k8s-cluster.yml`)
5. Ожидание доступности нод (`ansible-playbook -i inventory/mycluster/hosts.yaml wait-cluster-reachable.yml`)
6. Раскатка кластера kubespray'ем (`ansible-playbook -i inventory/mycluster/hosts.yaml cluster.yml`)
7. Обновление конфига для подключения к кластеру (`admin.conf` -> `$HOME/.kube/config`)
8. Проверка работоспособности

## 4. Само разворачивание кластера

Запускаем наш скрипт
```bash
$ cd /vagrant
$ . build.sh
```
и после длительного ожидания получаем полностью работоспособный кластер
```bash
$ kubectl get pods --all-namespaces
NAMESPACE     NAME                                       READY   STATUS    RESTARTS      AGE
kube-system   calico-kube-controllers-5fb8ccdcd6-lws7z   1/1     Running   0             2m44s
kube-system   calico-node-5tmjz                          1/1     Running   0             4m5s
kube-system   calico-node-6xdlj                          1/1     Running   0             4m5s
kube-system   calico-node-ffmzr                          1/1     Running   0             4m5s
kube-system   coredns-67cb94d654-f6wls                   1/1     Running   0             2m15s
kube-system   coredns-67cb94d654-wrnth                   1/1     Running   0             2m3s
kube-system   dns-autoscaler-7b6c6d8b5b-qvbzq            1/1     Running   0             2m7s
kube-system   kube-apiserver-stage-master-1              1/1     Running   1 (18s ago)   6m11s
kube-system   kube-controller-manager-stage-master-1     1/1     Running   2 (50s ago)   6m11s
kube-system   kube-proxy-fjdd7                           1/1     Running   0             5m
kube-system   kube-proxy-kb2vs                           1/1     Running   0             5m
kube-system   kube-proxy-sh7h2                           1/1     Running   0             5m
kube-system   kube-scheduler-stage-master-1              1/1     Running   2 (36s ago)   6m12s
kube-system   nginx-proxy-stage-worker-1                 1/1     Running   0             5m6s
kube-system   nginx-proxy-stage-worker-2                 1/1     Running   0             5m3s
kube-system   nodelocaldns-b4zfc                         1/1     Running   0             2m6s
kube-system   nodelocaldns-rlsdb                         1/1     Running   0             2m6s
kube-system   nodelocaldns-rrkzm                         1/1     Running   0             2m6s
$ kubectl get nodes --all-namespaces
NAME             STATUS   ROLES           AGE     VERSION
stage-master-1   Ready    control-plane   10m     v1.28.2
stage-worker-1   Ready    <none>          9m23s   v1.28.2
stage-worker-2   Ready    <none>          9m22s   v1.28.2
```
