# 13.2. Разделы и монтирование
>Приложение запущено и работает, но время от времени появляется необходимость передавать между бекендами данные. А сам бекенд генерирует статику для фронта. Нужно оптимизировать это.
>Для настройки NFS сервера можно воспользоваться следующей инструкцией (производить под пользователем на сервере, у которого есть доступ до kubectl):
>* установить helm: curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
>* добавить репозиторий чартов: helm repo add stable https://charts.helm.sh/stable && helm repo update
>* установить nfs-server через helm: helm install nfs-server stable/nfs-server-provisioner
>
>В конце установки будет выдан пример создания PVC для этого сервера.

### Шаг 1. Установка helm

```bash
$ curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 11156  100 11156    0     0  19469      0 --:--:-- --:--:-- --:--:-- 19435
Downloading https://get.helm.sh/helm-v3.10.1-linux-amd64.tar.gz
Verifying checksum... Done.
Preparing to install helm into /usr/local/bin
helm installed into /usr/local/bin/helm
$ helm repo add stable https://charts.helm.sh/stable && helm repo update
"stable" has been added to your repositories
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "gitlab" chart repository
...Successfully got an update from the "stable" chart repository
Update Complete. ⎈Happy Helming!⎈
```

### Шаг 2. Установка NFS сервера

```
$ kubectl config set-context --current --namespace=prod
$ helm install nfs-server stable/nfs-server-provisioner
WARNING: This chart is deprecated
NAME: nfs-server
LAST DEPLOYED: Sun Nov  6 10:33:53 2022
NAMESPACE: prod
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
The NFS Provisioner service has now been installed.

A storage class named 'nfs' has now been created
and is available to provision dynamic volumes.

You can use this storageclass by creating a `PersistentVolumeClaim` with the
correct storageClassName attribute. For example:

    ---
    kind: PersistentVolumeClaim
    apiVersion: v1
    metadata:
      name: test-dynamic-volume-claim
    spec:
      storageClassName: "nfs"
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 100Mi
```

## Задание 1: подключить для тестового конфига общую папку
>В stage окружении часто возникает необходимость отдавать статику бекенда сразу фронтом. Проще всего сделать это через общую папку. Требования:
>* в поде подключена общая папка между контейнерами (например, /static);
>* после записи чего-либо в контейнере с беком файлы можно получить из контейнера с фронтом.

### Шаг 1. Создаём конфигурацию для Pod'а на stage окружении

Воспользуемся контейнерами из предыдущего ДЗ и сконфигурируем новый отдельный Pod с шареной папкой `/static` в контейнере backend и таким же именем `/static` на frontend (в целом имена могут быть и разные). Создавать будем обычный Volume, т.к. контейнеры находятся в одном поде и данные не нужно хранить дольше жизненного цикла этого пода.
[stage_volume.yml](./stage_volume.yml)

### Шаг 2. Применим конфигурацию на stage

```bash
$ kubectl config set-context --current --namespace=stage
Context "yc-kubernates-cluster" modified.
$ kubectl apply -f stage/stage_volume.yml
pod/shared-volume created
$ kubectl get pods
NAME                    READY   STATUS    RESTARTS   AGE
db-0                    1/1     Running   0          4h2m
shared-volume           2/2     Running   0          15s
```

Проверим, что данные пробрасываются из backend во frontend

```bash
$ kubectl exec shared-volume -c backend -- ls -la /static
total 8
drwxrwxrwx 2 root root 4096 Nov  6 12:25 .
drwxr-xr-x 1 root root 4096 Nov  6 12:25 ..
$ kubectl exec shared-volume -c frontend -- ls -la /static
total 8
drwxrwxrwx 2 root root 4096 Nov  6 12:25 .
drwxr-xr-x 1 root root 4096 Nov  6 12:25 ..
kubectl exec shared-volume -c backend -- touch /static/dummy.txt
$ kubectl exec shared-volume -c frontend -- ls -la /static
total 8
drwxrwxrwx 2 root root 4096 Nov  6 12:28 .
drwxr-xr-x 1 root root 4096 Nov  6 12:25 ..
-rw-r--r-- 1 root root    0 Nov  6 12:28 dummy.txt
```
Файлик dummy.txt, созданный на backend, появился на frontend


## Задание 2: подключить общую папку для прода
>Поработав на stage, доработки нужно отправить на прод. В продуктиве у нас контейнеры крутятся в разных подах, поэтому потребуется PV и связь через PVC. Сам PV должен быть связан с NFS сервером. Требования:
>* все бекенды подключаются к одному PV в режиме ReadWriteMany;
>* фронтенды тоже подключаются к этому же PV с таким же режимом;
>* файлы, созданные бекендом, должны быть доступны фронту.
