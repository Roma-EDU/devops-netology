# Обновление приложений

>## Цель задания
>
>Выбрать и настроить стратегию обновления приложения.
>
>## Чеклист готовности к домашнему заданию
>
>1. Кластер K8s.
>
>## Инструменты и дополнительные материалы, которые пригодятся для выполнения задания
>
>1. [Документация Updating a Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#updating-a-deployment).
>2. [Статья про стратегии обновлений](https://habr.com/ru/companies/flant/articles/471620/).

### Шаг 1. Запускаем minikube

Подробности настройки см. в [предыдущем ДЗ](./../devkub-homeworks/13-kuber-homeworks-03-network)

```bash
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

$ minikube kubectl -- get deployment -A
NAMESPACE     NAME                      READY   UP-TO-DATE   AVAILABLE   AGE
kube-system   calico-kube-controllers   1/1     1            1           4d10h
kube-system   coredns                   1/1     1            1           4d10h
```

-----

## Задание 1. Выбрать стратегию обновления приложения и описать ваш выбор

>1. Имеется приложение, состоящее из нескольких реплик, которое требуется обновить.
>2. Ресурсы, выделенные для приложения, ограничены, и нет возможности их увеличить.
>3. Запас по ресурсам в менее загруженный момент времени составляет 20%.
>4. Обновление мажорное, новые версии приложения не умеют работать со старыми.
>5. Вам нужно объяснить свой выбор стратегии обновления приложения.

### Ответ

Исходя из пунктов 2 и 3 получаем, что в у нас просто есть "окно" на обновление, когда часть ресурсов высвобождается, а по завершении этого окна "лишних" ресурсов нет. Это значит, что параллельно поднимать 2 версии приложения, чтобы проверить его работоспособность, не имеет смысла (даже без учёта пункта 4). Тем самым от стратегий обновления `Blue/Green`, `Canary` и `A/B-теста` сразу отказываемся. Остаются варианты `Rolling Update` и `Recreate`. 

Если пункт 4 предполагает, что невозможно иметь поды с новой и старой версиями, то единственным выбором будет стратегия развёртывания `Recreate` с полной остановкой в обслуживании клиентов. Нужно выбрать подходящее время, уведомить потребителей и провести обновление. 

Если пункт 4 всё же допускает параллельный запуск подов разных версий, то в окно обновления стоит запустить `Rolling Update` с параметрами `maxSurge: 0` (нельзя превышать использование ресурсов) и `maxUnavailable: 20%` (нагрузка меньше на 20%, поэтому уберём соответствующее число подов из обслуживания запросов; возможно число должно быть чуть меньше, скажем 15-18%, зависит от количества реплик), чтобы не прерывать обслуживание клиентов. 

## Задание 2. Обновить приложение

>1. Создать deployment приложения с контейнерами nginx и multitool. Версию nginx взять 1.19. Количество реплик — 5.
>2. Обновить версию nginx в приложении до версии 1.20, сократив время обновления до минимума. Приложение должно быть доступно.
>3. Попытаться обновить nginx до версии 1.28, приложение должно оставаться доступным.
>4. Откатиться после неудачного обновления.

### Шаг 1. Поднимаем исходное состояние кластера (nginx:1.19)

Содержимое см. [nginx-1.19.yml](./nginx-1.19.yml)
```bash
$ minikube kubectl -- apply -f nginx-1.19.yml
deployment.apps/main created
$ minikube kubectl -- get pods
NAME                    READY   STATUS    RESTARTS   AGE
main-658888c7cf-9svxn   1/1     Running   0          25s
main-658888c7cf-rc4wv   1/1     Running   0          24s
main-658888c7cf-rqs2q   1/1     Running   0          24s
main-658888c7cf-sbnb5   1/1     Running   0          25s
main-658888c7cf-wllf5   1/1     Running   0          25s
```

### Шаг 2. Обновляем кластер до новой работающей версии (nginx:1.20)

Определяемся со статегией обновления. Допустим, что кластер в данный момент не нагружен, но при этом у нас есть требование сохранения его работоспособности. В этом случае нам подойдёт стратегия `Rolling Update` с сохранением 1-го или 2-х подов. Поэтому проставим `maxUnavailable: 3` (5 реплик - 2 работающих пода = 3 пода могут быть недоступны). И допустим мы можем позволить небольшое увеличиение ресурсов, поэтому пусть в превышении будет ещё 1 под `maxSurge: 1`
Содержимое см. [nginx-1.20.yml](./nginx-1.20.yml)

Запускаем второй терминал в режиме отслеживания подов (`minikube kubectl -- get pods --watch`) и применяем обновлённый deployment

Терминал 1:
```bash
$ minikube kubectl -- apply -f nginx-1.20.yml
deployment.apps/main configured
$ minikube kubectl -- get pods
NAME                   READY   STATUS    RESTARTS   AGE
main-c978bdc99-2l54s   1/1     Running   0          18m
main-c978bdc99-85sf2   1/1     Running   0          18m
main-c978bdc99-cbbmm   1/1     Running   0          18m
main-c978bdc99-jgtxx   1/1     Running   0          18m
main-c978bdc99-t7wlr   1/1     Running   0          18m
```

Терминал 2 (одинаковые строчки подряд убраны):
```bash
$ minikube kubectl -- get pods --watch
NAME                    READY   STATUS    RESTARTS   AGE
main-658888c7cf-9svxn   1/1     Running   0          2m37s
main-658888c7cf-rc4wv   1/1     Running   0          2m36s
main-658888c7cf-rqs2q   1/1     Running   0          2m36s
main-658888c7cf-sbnb5   1/1     Running   0          2m37s
main-658888c7cf-wllf5   1/1     Running   0          2m37s
main-c978bdc99-t7wlr    0/1     Pending   0          0s
main-c978bdc99-t7wlr    0/1     ContainerCreating   0          0s
main-658888c7cf-rc4wv   1/1     Terminating         0          3m20s
main-658888c7cf-9svxn   1/1     Terminating         0          3m21s
main-658888c7cf-sbnb5   1/1     Terminating         0          3m21s
main-c978bdc99-jgtxx    0/1     Pending             0          0s
main-c978bdc99-85sf2    0/1     Pending             0          0s
main-c978bdc99-2l54s    0/1     Pending             0          0s
main-c978bdc99-jgtxx    0/1     ContainerCreating   0          0s
main-c978bdc99-2l54s    0/1     ContainerCreating   0          0s
main-c978bdc99-85sf2    0/1     ContainerCreating   0          0s
main-658888c7cf-sbnb5   1/1     Terminating         0          3m22s
main-658888c7cf-rc4wv   1/1     Terminating         0          3m21s
main-658888c7cf-9svxn   1/1     Terminating         0          3m22s
main-658888c7cf-sbnb5   0/1     Terminating         0          3m24s
main-658888c7cf-9svxn   0/1     Terminating         0          3m24s
main-658888c7cf-rc4wv   0/1     Terminating         0          3m24s
main-c978bdc99-t7wlr    0/1     ContainerCreating   0          4s
main-c978bdc99-2l54s    0/1     ContainerCreating   0          4s
main-c978bdc99-jgtxx    0/1     ContainerCreating   0          4s
main-c978bdc99-85sf2    0/1     ContainerCreating   0          4s
main-c978bdc99-t7wlr    1/1     Running             0          21s
main-c978bdc99-2l54s    1/1     Running             0          21s
main-658888c7cf-rqs2q   1/1     Terminating         0          3m41s
main-c978bdc99-cbbmm    0/1     Pending             0          0s
main-c978bdc99-cbbmm    0/1     ContainerCreating   0          0s
main-658888c7cf-wllf5   1/1     Terminating         0          3m42s
main-658888c7cf-rqs2q   1/1     Terminating         0          3m41s
main-658888c7cf-rqs2q   0/1     Terminating         0          3m43s
main-c978bdc99-cbbmm    0/1     ContainerCreating   0          2s
main-658888c7cf-wllf5   0/1     Terminating         0          3m45s
main-c978bdc99-85sf2    1/1     Running             0          24s
main-c978bdc99-jgtxx    1/1     Running             0          24s
main-c978bdc99-cbbmm    1/1     Running             0          3s
```

### Шаг 3. Обновляем кластер до новой НЕработающей версии (nginx:1.28 - не существует на текущий момент)

Содержимое см. [nginx-1.28.yml](./nginx-1.28.yml)

Терминал 1:
```bash
$ minikube kubectl -- apply -f nginx-1.28.yml
deployment.apps/main configured
$ minikube kubectl -- get pods
NAME                   READY   STATUS             RESTARTS   AGE
main-975c7598c-7sp9h   0/1     ImagePullBackOff   0          22s
main-975c7598c-9qqqh   0/1     ImagePullBackOff   0          22s
main-975c7598c-fsrnx   0/1     ErrImagePull       0          22s
main-975c7598c-jcpfm   0/1     ImagePullBackOff   0          22s
main-c978bdc99-cbbmm   1/1     Running            0          31m
main-c978bdc99-jgtxx   1/1     Running            0          31m
```
Видим, что часть подов продолжает функционировать

Терминал 2:
```bash
$ minikube kubectl -- get pods --watch
NAME                   READY   STATUS    RESTARTS   AGE
main-c978bdc99-2l54s   1/1     Running   0          31m
main-c978bdc99-85sf2   1/1     Running   0          31m
main-c978bdc99-cbbmm   1/1     Running   0          30m
main-c978bdc99-jgtxx   1/1     Running   0          31m
main-c978bdc99-t7wlr   1/1     Running   0          31m
main-975c7598c-9qqqh   0/1     Pending   0          0s
main-975c7598c-9qqqh   0/1     Pending   0          0s
main-c978bdc99-85sf2   1/1     Terminating   0          31m
main-975c7598c-9qqqh   0/1     ContainerCreating   0          0s
main-c978bdc99-t7wlr   1/1     Terminating         0          31m
main-c978bdc99-2l54s   1/1     Terminating         0          31m
main-975c7598c-jcpfm   0/1     Pending             0          0s
main-975c7598c-fsrnx   0/1     Pending             0          0s
...
main-975c7598c-fsrnx   0/1     ImagePullBackOff   0          2m46s
main-975c7598c-jcpfm   0/1     ImagePullBackOff   0          2m46s
main-c978bdc99-cbbmm   1/1     Running            0          33m
main-c978bdc99-jgtxx   1/1     Running            0          34m
main-975c7598c-7sp9h   0/1     ErrImagePull       0          3m14s
main-975c7598c-9qqqh   0/1     ErrImagePull       0          3m22s
main-975c7598c-fsrnx   0/1     ErrImagePull       0          3m25s
main-975c7598c-7sp9h   0/1     ImagePullBackOff   0          3m29s
main-975c7598c-9qqqh   0/1     ImagePullBackOff   0          3m33s
main-975c7598c-jcpfm   0/1     ErrImagePull       0          3m34s
main-975c7598c-fsrnx   0/1     ImagePullBackOff   0          3m37s
main-975c7598c-jcpfm   0/1     ImagePullBackOff   0          3m49s
```

### Шаг 4. Откатываем до предыдущей работающей версии

Откатываем наш deployment до предыдущей версии с помощью команды `kubectl rollout undo deployment/<name-of-deployment>`
```bash
$ minikube kubectl -- rollout undo deployment/main
deployment.apps/main rolled back
$ minikube kubectl -- get pods
NAME                   READY   STATUS    RESTARTS   AGE
main-c978bdc99-25b5x   1/1     Running   0          6s
main-c978bdc99-68k7f   1/1     Running   0          6s
main-c978bdc99-cbbmm   1/1     Running   0          39m
main-c978bdc99-gc4jr   1/1     Running   0          6s
main-c978bdc99-jgtxx   1/1     Running   0          39m
```

### Шаг 5*. Останавливаем кластер

```bash
$ minikube stop
✋  Stopping node "minikube"  ...
🛑  Powering off "minikube" via SSH ...
🛑  1 node stopped.
$ exit
logout
Connection to 127.0.0.1 closed.

>vagrant halt
==> default: Attempting graceful shutdown of VM...
```

## ~~Задание 3*. Создать Canary deployment~~

>1. Создать два deployment'а приложения nginx.
>2. При помощи разных ConfigMap сделать две версии приложения — веб-страницы.
>3. С помощью ingress создать канареечный деплоймент, чтобы можно было часть трафика перебросить на разные версии приложения.
