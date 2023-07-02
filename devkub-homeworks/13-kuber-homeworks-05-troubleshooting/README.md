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
