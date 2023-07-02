# Troubleshooting

>## Цель задания
>
>Устранить неисправности при деплое приложения.
>
>## Чеклист готовности к домашнему заданию
>
>1. Кластер K8s.

Развернём локальный кластер K8s с помощью `minikube` (подробнее в предыдущем ДЗ)
```shell
$ minikube start
😄  minikube v1.30.1 on Ubuntu 22.04 (vbox/amd64)
✨  Using the docker driver based on existing profile

🧯  The requested memory allocation of 2200MiB does not leave room for system overhead (total system memory: 2980MiB). You may face stability issues.
💡  Suggestion: Start minikube with less memory allocated: 'minikube start --memory=2200mb'

👍  Starting control plane node minikube in cluster minikube
🚜  Pulling base image ...
🔄  Restarting existing docker container for "minikube" ...
🐳  Preparing Kubernetes v1.26.3 on Docker 23.0.2 ...
🔗  Configuring Calico (Container Networking Interface) ...
🔎  Verifying Kubernetes components...
    ▪ Using image gcr.io/k8s-minikube/storage-provisioner:v5
🌟  Enabled addons: default-storageclass, storage-provisioner
💡  kubectl not found. If you need it, try: 'minikube kubectl -- get pods -A'
🏄  Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default

$ minikube kubectl -- get pods -A
NAMESPACE     NAME                                      READY   STATUS    RESTARTS        AGE
kube-system   calico-kube-controllers-7bdbfc669-28h8n   1/1     Running   4 (3d10h ago)   7d21h
kube-system   calico-node-fmtzm                         1/1     Running   3 (3d10h ago)   7d21h
kube-system   coredns-787d4945fb-779wq                  1/1     Running   5 (4m59s ago)   7d21h
kube-system   etcd-minikube                             1/1     Running   3 (3d10h ago)   7d21h
kube-system   kube-apiserver-minikube                   1/1     Running   4 (3m40s ago)   7d21h
kube-system   kube-controller-manager-minikube          1/1     Running   5 (3m40s ago)   7d21h
kube-system   kube-proxy-dvpv8                          1/1     Running   3 (3d10h ago)   7d21h
kube-system   kube-scheduler-minikube                   1/1     Running   3 (3d10h ago)   7d21h
kube-system   storage-provisioner                       1/1     Running   6 (3d10h ago)   7d21h
```

## Задание. При деплое приложение web-consumer не может подключиться к auth-db. Необходимо это исправить

>1. Установить приложение по команде:
>```shell
>kubectl apply -f https://raw.githubusercontent.com/netology-code/kuber-homeworks/main/3.5/files/task.yaml
>```
>2. Выявить проблему и описать.
>3. Исправить проблему, описать, что сделано.
>4. Продемонстрировать, что проблема решена.

### Шаг 1. Установим приложение

```shell
$ minikube kubectl -- apply -f https://raw.githubusercontent.com/netology-code/kuber-homeworks/main/3.5
/files/task.yaml
Error from server (NotFound): error when creating "https://raw.githubusercontent.com/netology-code/kuber-homeworks/main/3.5/files/task.yaml": namespaces "web" not found
Error from server (NotFound): error when creating "https://raw.githubusercontent.com/netology-code/kuber-homeworks/main/3.5/files/task.yaml": namespaces "data" not found
Error from server (NotFound): error when creating "https://raw.githubusercontent.com/netology-code/kuber-homeworks/main/3.5/files/task.yaml": namespaces "data" not found
```

Видим, что нет нужных namespace'ов, добавим и повторим установку:
```shell
$ minikube kubectl -- create namespace data
namespace/data created
$ minikube kubectl -- create namespace web
namespace/web created
$ minikube kubectl -- apply -f https://raw.githubusercontent.com/netology-code/kuber-homeworks/main/3.5/files/task.yaml
deployment.apps/web-consumer created
deployment.apps/auth-db created
service/auth-db created
$ minikube kubectl -- get pods -A
NAMESPACE     NAME                                      READY   STATUS    RESTARTS        AGE
data          auth-db-795c96cddc-2z5tl                  1/1     Running   0               31s
kube-system   calico-kube-controllers-7bdbfc669-28h8n   1/1     Running   4 (3d16h ago)   8d
kube-system   calico-node-fmtzm                         1/1     Running   3 (3d16h ago)   8d
kube-system   coredns-787d4945fb-779wq                  1/1     Running   5 (5h29m ago)   8d
kube-system   etcd-minikube                             1/1     Running   3 (3d16h ago)   8d
kube-system   kube-apiserver-minikube                   1/1     Running   4 (5h28m ago)   8d
kube-system   kube-controller-manager-minikube          1/1     Running   5 (5h28m ago)   8d
kube-system   kube-proxy-dvpv8                          1/1     Running   3 (3d16h ago)   8d
kube-system   kube-scheduler-minikube                   1/1     Running   3 (3d16h ago)   8d
kube-system   storage-provisioner                       1/1     Running   6 (3d16h ago)   8d
web           web-consumer-577d47b97d-kmww6             1/1     Running   0               31s
web           web-consumer-577d47b97d-r429q             1/1     Running   0               31s
```

Поды поднялись, с этим всё хорошо.

### Шаг 2. Ищем проблему

Посмотрим логи `logs web-consumer-577d47b97d-kmww6` и описание `describe pod web-consumer-577d47b97d-kmww6` одного из проблемных подов
```shell
$ minikube kubectl -- logs web-consumer-577d47b97d-kmww6 -n=web
curl: (6) Couldn't resolve host 'auth-db'
curl: (6) Couldn't resolve host 'auth-db'
curl: (6) Couldn't resolve host 'auth-db'
curl: (6) Couldn't resolve host 'auth-db'
curl: (6) Couldn't resolve host 'auth-db'
curl: (6) Couldn't resolve host 'auth-db'
$ minikube kubectl -- describe pod web-consumer-577d47b97d-kmww6 -n=web
Name:             web-consumer-577d47b97d-kmww6
Namespace:        web
Priority:         0
Service Account:  default
Node:             minikube/192.168.49.2
Start Time:       Sun, 02 Jul 2023 14:43:06 +0000
Labels:           app=web-consumer
                  pod-template-hash=577d47b97d
Annotations:      cni.projectcalico.org/containerID: 41ae957a51d27489ddd1eaf0ba848c56142f9beafe3a65c510814207b289f090
                  cni.projectcalico.org/podIP: 10.244.120.114/32
                  cni.projectcalico.org/podIPs: 10.244.120.114/32
Status:           Running
IP:               10.244.120.114
IPs:
  IP:           10.244.120.114
Controlled By:  ReplicaSet/web-consumer-577d47b97d
Containers:
  busybox:
    Container ID:  docker://6ce91d9e15153e8cf9efcf9325f75fda456c63d5de40213ab444aa9a314ac3c9
    Image:         radial/busyboxplus:curl
    Image ID:      docker-pullable://radial/busyboxplus@sha256:a68c05ab1112fd90ad7b14985a48520e9d26dbbe00cb9c09aa79fdc0ef46b372
    Port:          <none>
    Host Port:     <none>
    Command:
      sh
      -c
      while true; do curl auth-db; sleep 5; done
    State:          Running
      Started:      Sun, 02 Jul 2023 14:43:15 +0000
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-4zp5k (ro)
Conditions:
  Type              Status
  Initialized       True
  Ready             True
  ContainersReady   True
  PodScheduled      True
Volumes:
  kube-api-access-4zp5k:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason     Age    From               Message
  ----    ------     ----   ----               -------
  Normal  Scheduled  8m1s   default-scheduler  Successfully assigned web/web-consumer-577d47b97d-kmww6 to minikube
  Normal  Pulling    7m59s  kubelet            Pulling image "radial/busyboxplus:curl"
  Normal  Pulled     7m52s  kubelet            Successfully pulled image "radial/busyboxplus:curl" in 2.480622473s (6.750778208s including waiting)
  Normal  Created    7m52s  kubelet            Created container busybox
  Normal  Started    7m52s  kubelet            Started container busybox
```

Видим, что используется `curl auth-db`, без указания namespace'а

### Шаг 3. Правим конфигурацию

Берём исходники deployment'а (или получаем их с помощью `minikube kubectl -- get deployment web-consumer -n=web -o yaml > web-deployment.yml`) и прописываем корректный путь до сервиса `curl auth-db` -> `curl auth-db.data.svc.cluster.local`:  [web-deployment.yml](./web-deployment.yml) и применяем её
```shell
$ minikube kubectl -- apply -f web-deployment.yml
deployment.apps/web-consumer configured
$ minikube kubectl -- get pods -A
NAMESPACE     NAME                                      READY   STATUS    RESTARTS        AGE
data          auth-db-795c96cddc-2z5tl                  1/1     Running   0               42m
kube-system   calico-kube-controllers-7bdbfc669-28h8n   1/1     Running   4 (3d16h ago)   8d
kube-system   calico-node-fmtzm                         1/1     Running   3 (3d16h ago)   8d
kube-system   coredns-787d4945fb-779wq                  1/1     Running   5 (6h12m ago)   8d
kube-system   etcd-minikube                             1/1     Running   3 (3d16h ago)   8d
kube-system   kube-apiserver-minikube                   1/1     Running   4 (6h10m ago)   8d
kube-system   kube-controller-manager-minikube          1/1     Running   5 (6h10m ago)   8d
kube-system   kube-proxy-dvpv8                          1/1     Running   3 (3d16h ago)   8d
kube-system   kube-scheduler-minikube                   1/1     Running   3 (3d16h ago)   8d
kube-system   storage-provisioner                       1/1     Running   6 (3d16h ago)   8d
web           web-consumer-7f687d84fc-2ghpx             1/1     Running   0               37s
web           web-consumer-7f687d84fc-w6nvq             1/1     Running   0               35s
```

### Шаг 4. Проверяем, что всё работает

Снова смотрим логи и убеждаемся, что страница по curl отдаётся:
```shell
$ minikube kubectl -- logs web-consumer-7f687d84fc-2ghpx -n
=web
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

### Шаг 5*. Останавливаем кластер

```shell
$ minikube stop
✋  Stopping node "minikube"  ...
🛑  Powering off "minikube" via SSH ...
🛑  1 node stopped.
$ exit
logout
Connection to 127.0.0.1 closed.

D:\HashiCorp\Ubuntu\minicube>vagrant halt
==> default: Attempting graceful shutdown of VM...
```
