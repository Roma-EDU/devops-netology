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


### Шаг 2. Настраиваем kubespray (на локальной машине)

Выкачиваем репозиторий kubespray, доустанавливаем зависимости
```bash
$ git clone https://github.com/kubernetes-sigs/kubespray
$ cd kubespray
$ sudo apt-get update
$ sudo apt-get install -y pip
$ sudo pip3 install -r requirements.txt
```

Заодно поставим kubectl и kubeadm версии 1.24.4 (такая же используется в kubespray) и зафиксируем их от обновления
```bash
$ sudo apt-get install -y apt-transport-https ca-certificates curl
$ sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
$ echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
$ sudo apt-get update
$ sudo apt-get install -y kubelet=1.24.4-00 kubeadm=1.24.4-00 kubectl=1.24.4-00 containerd
$ sudo apt-mark hold kubelet kubeadm kubectl
```


### Шаг 3. Настраиваем конфигурацию kubespray

Скопируем готовый пример 
```bash
$ cp -rfp inventory/sample inventory/mycluster
```

Настроим его конфигурацию, подав во вспомогательную утилиту **внутренние IP** всех нод: и рабочих и мастера
```bash
$ declare -a IPS=(10.0.0.34 10.0.0.8 10.0.0.13 10.0.0.20 10.0.0.23)
$ CONFIG_FILE=inventory/mycluster/hosts.yaml python3 contrib/inventory_builder/inventory.py ${IPS[@]}
```

Отредактируем полученный [hosts.yaml](./inventory/mycluster/hosts.yaml):
* Переименуем ноды согласно названию сервера (node1 -> cp1, node2 -> node1)
* Пропишем корректрые публичные IP в поле `ansible_host` (нужно для работы ансибла, другие поля ip и access_ip редактировать не надо, чтобы общение между нодами шло через локальную нетарифицируемую сеть)
* Поправим пользователя, от имени которого выполняется настройка `ansible_user`
* Поправим хосты для мастер-нод kube_control_plane и рабочих нод kube_node
* Поправим расположение etcd

Настройки самого kubernates-кластера производятся в файлике `inventory/mycluster/group_vars/k8s-cluster/k8s-cluster.yaml`. В нашем случае нужно обновить только параметр 
```yaml
container_manager: docker
```


### Шаг 4. Запускаем развёртывание кластера

Запускаем процесс развёртывания кластера с помощью ansible и долго ждём. Затем, после успешного завершения установки, подключаемся на мастер-ноду и копируем ключи для удалённого подключения
```bash
$ ansible-playbook -i inventory/mycluster/hosts.yaml cluster.yml -b -v
$ ssh ubuntu@51.250.10.22
$ cat /etc/kubernetes/admin.conf
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: <PRIVATE_AUTHORITY_DATA>
    server: https://127.0.0.1:6443
  name: cluster.local
contexts:
- context:
    cluster: cluster.local
    user: kubernetes-admin
  name: kubernetes-admin@cluster.local
current-context: kubernetes-admin@cluster.local
kind: Config
preferences: {}
users:
- name: kubernetes-admin
  user:
    client-certificate-data: <PRIVATE_CERTIFICATE_DATA>
    client-key-data:  <PRIVATE_KEY_DATA>
$ exit
```

Меняем IP-адрес сервера с локального 127.0.0.1 на публичный 51.250.10.22 и сохраняем на локальном компьютере в файл `~/.kube/config` для подключения к кластеру
```bash
$ mkdir -p $HOME/.kube
$ nano $HOME/.kube/config
$ sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### Шаг 5. Разрешаем удалённое подключение к кластеру

Команда `kubectl get nodes` завершается с ошибкой, поскольку не настроен сертификат для работы через публичный IP. Ещё раз редактируем файл `inventory/mycluster/group_vars/k8s-cluster/k8s-cluster.yaml`, раскомментировав свойство `supplementary_addresses_in_ssl_keys` и прописав в него публичный IP. 
```yaml
supplementary_addresses_in_ssl_keys: [51.250.10.22]
```

Затем повторно прогоним ansible 
```bash
$ ansible-playbook -i inventory/mycluster/hosts.yaml cluster.yml -b -v
...
PLAY RECAP ********************************************************************************************************
cp1                        : ok=644  changed=29   unreachable=0    failed=0    skipped=1202 rescued=0    ignored=2
localhost                  : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
node1                      : ok=431  changed=15   unreachable=0    failed=0    skipped=713  rescued=0    ignored=2
node2                      : ok=431  changed=15   unreachable=0    failed=0    skipped=712  rescued=0    ignored=2
node3                      : ok=431  changed=15   unreachable=0    failed=0    skipped=712  rescued=0    ignored=2
node4                      : ok=431  changed=15   unreachable=0    failed=0    skipped=712  rescued=0    ignored=2
```

Проверим, что успешно подключаемся с локальной машины
```bash
$ kubectl get nodes -o wide
NAME    STATUS   ROLES          AGE   VERSION   INTERNAL-IP  EXTERNAL-IP  OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
cp1     Ready    control-plane  88m   v1.24.4   10.0.0.34    <none>       Ubuntu 20.04.3 LTS   5.4.0-96-generic   docker://20.10.17
node1   Ready    <none>         86m   v1.24.4   10.0.0.8     <none>       Ubuntu 20.04.3 LTS   5.4.0-96-generic   docker://20.10.17
node2   Ready    <none>         86m   v1.24.4   10.0.0.13    <none>       Ubuntu 20.04.3 LTS   5.4.0-96-generic   docker://20.10.17
node3   Ready    <none>         86m   v1.24.4   10.0.0.20    <none>       Ubuntu 20.04.3 LTS   5.4.0-96-generic   docker://20.10.17
node4   Ready    <none>         86m   v1.24.4   10.0.0.23    <none>       Ubuntu 20.04.3 LTS   5.4.0-96-generic   docker://20.10.17
```


## ~Задание 2 (*): подготовить и проверить инвентарь для кластера в AWS~
>Часть новых проектов хотят запускать на мощностях AWS. Требования похожи:
>* разворачивать 5 нод: 1 мастер и 4 рабочие ноды;
>* работать должны на минимально допустимых EC2 — t3.small.
