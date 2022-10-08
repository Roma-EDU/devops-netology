# 12.2. Команды для работы с Kubernetes
>Кластер — это сложная система, с которой крайне редко работает один человек. Квалифицированный devops умеет наладить работу всей команды, занимающейся каким-либо сервисом.
>После знакомства с кластером вас попросили выдать доступ нескольким разработчикам. Помимо этого требуется служебный аккаунт для просмотра логов.

## Задание 1: Запуск пода из образа в деплойменте
>Для начала следует разобраться с прямым запуском приложений из консоли. Такой подход поможет быстро развернуть инструменты отладки в кластере. Требуется запустить деплоймент на основе образа из hello world уже через deployment. Сразу стоит запустить 2 копии приложения (replicas=2). 
>
>Требования:
> * пример из hello world запущен в качестве deployment
> * количество реплик в deployment установлено в 2
> * наличие deployment можно проверить командой kubectl get deployment
> * наличие подов можно проверить командой kubectl get pods

**Ответ**:

### Шаг 0. Поднимем кластер minikube

Установим minikube и kubectl.
Подробности в предыдущем ДЗ [12-kubernetes-01-intro](../12-kubernetes-01-intro)

А также создадим namespace для задачи 2 и перейдём в него
```bash
$ kubectl create namespace app-namespace
namespace/app-namespace created
$ kubectl config set-context --current --namespace=app-namespace
Context "minikube" modified.
```


### Шаг 1. Развернём деплоймент

С помощью `kubectl create deployment` создадим деплоймент на основе образа из hello world, зададим ему 2 реплики `--replicas=2` и проверим, что получилось 
```bash
$ kubectl create deployment hello-node --image=k8s.gcr.io/echoserver:1.4 --replicas=2
deployment.apps/hello-node created
$ kubectl get deployment
NAME         READY   UP-TO-DATE   AVAILABLE   AGE
hello-node   2/2     2            2           33s
$ kubectl get pods
NAME                         READY   STATUS    RESTARTS   AGE
hello-node-697897c86-47x5q   1/1     Running   0          28s
hello-node-697897c86-hqwpb   1/1     Running   0          28s
```


## Задание 2: Просмотр логов для разработки
>Разработчикам крайне важно получать обратную связь от штатно работающего приложения и, еще важнее, об ошибках в его работе. 
>Требуется создать пользователя и выдать ему доступ на чтение конфигурации и логов подов в app-namespace.
>
>Требования: 
> * создан новый токен доступа для пользователя
> * пользователь прописан в локальный конфиг (~/.kube/config, блок users)
> * пользователь может просматривать логи подов и их конфигурацию (kubectl logs pod <pod_id>, kubectl describe pod <pod_id>)

**Ответ**:

### Шаг 1. Создадим роль для "разрабочиков"

В этой роли описываются права, с какими ресурсами и что можно делать
```bash
$ kubectl create role developers --verb=get,list --resource=pods,pods/log
role.rbac.authorization.k8s.io/developers created
```

### Шаг 2. Создадим сервисный аккаунт для конкретного разрабочика

Пусть его будут звать developer1, а также добавим ему токен и пропишем в конфиг
```bash
$ kubectl create serviceaccount developer1
serviceaccount/developer1 created

$ kubectl create token developer1
eyJhbGciOiJSUzI1NiIsImtpZCI6InVOdUNyQm1ZQ3V5SFAwS052eUJ3bEJhRjJIZDAtTFQ0SFcwblVlcjBLQ0kifQ.eyJhdWQiOlsiaHR0cHM6Ly9rdWJlcm5ldGVzLmRlZmF1bHQuc3ZjLmNsdXN0ZXIubG9jYWwiXSwiZXhwIjoxNjY1MjQ5MDA1LCJpYXQiOjE2NjUyNDU0MDUsImlzcyI6Imh0dHBzOi8va3ViZXJuZXRlcy5kZWZhdWx0LnN2Yy5jbHVzdGVyLmxvY2FsIiwia3ViZXJuZXRlcy5pbyI6eyJuYW1lc3BhY2UiOiJhcHAtbmFtZXNwYWNlIiwic2VydmljZWFjY291bnQiOnsibmFtZSI6ImRldmVsb3BlcjEiLCJ1aWQiOiIwMGNmMDNiMC1mZjRkLTQ2NWMtOTNlMy0xZmI4MzhlZWY0MWQifX0sIm5iZiI6MTY2NTI0NTQwNSwic3ViIjoic3lzdGVtOnNlcnZpY2VhY2NvdW50OmFwcC1uYW1lc3BhY2U6ZGV2ZWxvcGVyMSJ9.CiTNtaA7zr2hjQK_bdSTwcIYWuB_-Me3kUM_SjES82-nDQoMQtav1briaJSeYeXtF1sc7WsBRe1gXPlerhHv1HKES6hNWbnf_R6__BI5Z_2eX5Fq9wnbQqwOTFePJmUnRyG2WWiDvwsjqhijSrLymerxIQLVos-6Nwp-keBI3fbFa4Jbn-Urx9ZFUVwqqEJwojfzBSAF2CzonyvKpDqPyaTCqwNCnpKJUhvuPCckxAzfd9ewd-DDuFX7q6bhqd-WQ6gP3cw77L2Z3mkn7jzhcaNWjLhUtQ78Bk2YA5V_-Qs68UUkH80gddbGtUapQAnSvsiyySddxSE1bFt8vbImeQ

$ kubectl config set-credentials developer1 --token eyJhbGciOiJSUzI1NiIsImtpZCI6InVOdUNyQm1ZQ3V5SFAwS052eUJ3bEJhRjJIZDAtTFQ0SFcwblVlcjBLQ0kifQ.eyJhdWQiOlsiaHR0cHM6Ly9rdWJlcm5ldGVzLmRlZmF1bHQuc3ZjLmNsdXN0ZXIubG9jYWwiXSwiZXhwIjoxNjY1MjQ5MDA1LCJpYXQiOjE2NjUyNDU0MDUsImlzcyI6Imh0dHBzOi8va3ViZXJuZXRlcy5kZWZhdWx0LnN2Yy5jbHVzdGVyLmxvY2FsIiwia3ViZXJuZXRlcy5pbyI6eyJuYW1lc3BhY2UiOiJhcHAtbmFtZXNwYWNlIiwic2VydmljZWFjY291bnQiOnsibmFtZSI6ImRldmVsb3BlcjEiLCJ1aWQiOiIwMGNmMDNiMC1mZjRkLTQ2NWMtOTNlMy0xZmI4MzhlZWY0MWQifX0sIm5iZiI6MTY2NTI0NTQwNSwic3ViIjoic3lzdGVtOnNlcnZpY2VhY2NvdW50OmFwcC1uYW1lc3BhY2U6ZGV2ZWxvcGVyMSJ9.CiTNtaA7zr2hjQK_bdSTwcIYWuB_-Me3kUM_SjES82-nDQoMQtav1briaJSeYeXtF1sc7WsBRe1gXPlerhHv1HKES6hNWbnf_R6__BI5Z_2eX5Fq9wnbQqwOTFePJmUnRyG2WWiDvwsjqhijSrLymerxIQLVos-6Nwp-keBI3fbFa4Jbn-Urx9ZFUVwqqEJwojfzBSAF2CzonyvKpDqPyaTCqwNCnpKJUhvuPCckxAzfd9ewd-DDuFX7q6bhqd-WQ6gP3cw77L2Z3mkn7jzhcaNWjLhUtQ78Bk2YA5V_-Qs68UUkH80gddbGtUapQAnSvsiyySddxSE1bFt8vbImeQ
User "developer1" set.
```

### Шаг 3. Назначим права

Просто привяжем роль к конкретному аккаунту (namespace указывать обязательно)
```bash
$ kubectl create rolebinding dev1-binding --role=developers --serviceaccount=app-namespace:developer1
rolebinding.rbac.authorization.k8s.io/dev1-binding created
```

### Шаг 4. Проверка

Переключимся в аккаунт разработчика и проверим что ему можно
```bash
$ kubectl config set-context minikube --user developer1
Context "minikube" modified.

$ kubectl get pods
NAME                         READY   STATUS    RESTARTS   AGE
hello-node-697897c86-pzkc2   1/1     Running   0          37m
hello-node-697897c86-s99z4   1/1     Running   0          37m

$ kubectl delete pod hello-node-697897c86-s99z4
Error from server (Forbidden): pods "hello-node-697897c86-s99z4" is forbidden: User "system:serviceaccount:app-namespace:developer1" cannot delete resource "pods" in API group "" in the namespace "app-namespace"
$ kubectl logs hello-node-697897c86-pzkc2
$ kubectl describe pod hello-node-697897c86-s99z4
Name:             hello-node-697897c86-s99z4
Namespace:        app-namespace
Priority:         0
...

$ kubectl config set-context minikube --user minikube
Context "minikube" modified.
```
Смотреть ноды можно, а удалять нельзя - всё как планировали

И содержимое `~/.kube/config`
```
$ cat ~/.kube/config
apiVersion: v1
clusters:
- cluster:
    certificate-authority: /home/roma/.minikube/ca.crt
    extensions:
    - extension:
        last-update: Sat, 08 Oct 2022 11:11:56 UTC
        provider: minikube.sigs.k8s.io
        version: v1.27.1
      name: cluster_info
    server: https://192.168.49.2:8443
  name: minikube
contexts:
- context:
    cluster: minikube
    extensions:
    - extension:
        last-update: Sat, 08 Oct 2022 11:11:56 UTC
        provider: minikube.sigs.k8s.io
        version: v1.27.1
      name: context_info
    namespace: app-namespace
    user: minikube
  name: minikube
current-context: minikube
kind: Config
preferences: {}
users:
- name: developer1
  user:
    token: eyJhbGciOiJSUzI1NiIsImtpZCI6InVOdUNyQm1ZQ3V5SFAwS052eUJ3bEJhRjJIZDAtTFQ0SFcwblVlcjBLQ0kifQ.eyJhdWQiOlsiaHR0cHM6Ly9rdWJlcm5ldGVzLmRlZmF1bHQuc3ZjLmNsdXN0ZXIubG9jYWwiXSwiZXhwIjoxNjY1MjQ5MDA1LCJpYXQiOjE2NjUyNDU0MDUsImlzcyI6Imh0dHBzOi8va3ViZXJuZXRlcy5kZWZhdWx0LnN2Yy5jbHVzdGVyLmxvY2FsIiwia3ViZXJuZXRlcy5pbyI6eyJuYW1lc3BhY2UiOiJhcHAtbmFtZXNwYWNlIiwic2VydmljZWFjY291bnQiOnsibmFtZSI6ImRldmVsb3BlcjEiLCJ1aWQiOiIwMGNmMDNiMC1mZjRkLTQ2NWMtOTNlMy0xZmI4MzhlZWY0MWQifX0sIm5iZiI6MTY2NTI0NTQwNSwic3ViIjoic3lzdGVtOnNlcnZpY2VhY2NvdW50OmFwcC1uYW1lc3BhY2U6ZGV2ZWxvcGVyMSJ9.CiTNtaA7zr2hjQK_bdSTwcIYWuB_-Me3kUM_SjES82-nDQoMQtav1briaJSeYeXtF1sc7WsBRe1gXPlerhHv1HKES6hNWbnf_R6__BI5Z_2eX5Fq9wnbQqwOTFePJmUnRyG2WWiDvwsjqhijSrLymerxIQLVos-6Nwp-keBI3fbFa4Jbn-Urx9ZFUVwqqEJwojfzBSAF2CzonyvKpDqPyaTCqwNCnpKJUhvuPCckxAzfd9ewd-DDuFX7q6bhqd-WQ6gP3cw77L2Z3mkn7jzhcaNWjLhUtQ78Bk2YA5V_-Qs68UUkH80gddbGtUapQAnSvsiyySddxSE1bFt8vbImeQ
- name: minikube
  user:
    client-certificate: /home/roma/.minikube/profiles/minikube/client.crt
    client-key: /home/roma/.minikube/profiles/minikube/client.key
```

## Задание 3: Изменение количества реплик 
>Поработав с приложением, вы получили запрос на увеличение количества реплик приложения для нагрузки. Необходимо изменить запущенный deployment, увеличив количество реплик до 5. Посмотрите статус запущенных подов после увеличения реплик. 
>
>Требования:
> * в deployment из задания 1 изменено количество реплик на 5
> * проверить что все поды перешли в статус running (kubectl get pods)

**Ответ**:

### Шаг 1. Изменим количество реплик

Воспользуемся командой `scale`
```bash
$ kubectl scale --replicas=5 deployment/hello-node
deployment.apps/hello-node scaled
$ kubectl get pods
NAME                         READY   STATUS    RESTARTS   AGE
hello-node-697897c86-pzkc2   1/1     Running   0          60m
hello-node-697897c86-s8ktc   1/1     Running   0          31s
hello-node-697897c86-s99z4   1/1     Running   0          60m
hello-node-697897c86-tjskx   1/1     Running   0          31s
hello-node-697897c86-xfstk   1/1     Running   0          31s
```
