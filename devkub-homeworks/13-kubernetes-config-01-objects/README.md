# 13.1. Контейнеры, поды, deployment, statefulset, services, endpoints
> Настроив кластер, подготовьте приложение к запуску в нём. Приложение стандартное: бекенд, фронтенд, база данных. Его можно найти в папке [13-kubernetes-config](https://github.com/netology-code/devkub-homeworks/tree/main/13-kubernetes-config).

### Шаг 1. Настройка Docker-образов

Скачиваем исходники приложения (папочки backend и frontend), собираем из них Docker-образы, логинимся и пушим в репозиторий

```bash
$ cd backend
$ docker build -t roma4edu/netology_kube_backend:1.0 .
Sending build context to Docker daemon  19.46kB
Step 1/8 : FROM python:3.9-buster
3.9-buster: Pulling from library/python
...
$ cd ../frontend/
$ docker build -t roma4edu/netology_kube_frontend:1.0 .
Sending build context to Docker daemon  429.6kB
Step 1/14 : FROM node:lts-buster as builder
lts-buster: Pulling from library/node
...
$ docker login -u roma4edu
Password:
WARNING! Your password will be stored unencrypted in /home/vagrant/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
$ docker push roma4edu/netology_kube_backend:1.0
The push refers to repository [docker.io/roma4edu/netology_kube_backend]
...
$ docker push roma4edu/netology_kube_frontend:1.0
The push refers to repository [docker.io/roma4edu/netology_kube_frontend]
```
В итоге получаем образы для [backend](https://hub.docker.com/repository/docker/roma4edu/netology_kube_backend) и [frontend](https://hub.docker.com/repository/docker/roma4edu/netology_kube_frontend)


### Шаг 2. Разворачивание кластера Kubernates

Воспользуемся Managed Kubernates из [Yandex.Cloud](https://cloud.yandex.ru/docs/managed-kubernetes/quickstart?from=int-console-empty-state)
```bash
$ yc init
...
$ yc managed-kubernetes cluster get-credentials kubernates-cluster --external

Context 'yc-kubernates-cluster' was added as default to kubeconfig '/home/vagrant/.kube/config'.
Check connection to cluster using 'kubectl cluster-info --kubeconfig /home/vagrant/.kube/config'.

Note, that authentication depends on 'yc' and its config profile 'default'.
To access clusters using the Kubernetes API, please use Kubernetes Service Account.
```

## Задание 1: подготовить тестовый конфиг для запуска приложения
>Для начала следует подготовить запуск приложения в stage окружении с простыми настройками. Требования:
>* под содержит в себе 2 контейнера — фронтенд, бекенд;
>* регулируется с помощью deployment фронтенд и бекенд;
>* база данных — через statefulset.

**Ответ**:

### Шаг 1. 


## Задание 2: подготовить конфиг для production окружения
>Следующим шагом будет запуск приложения в production окружении. Требования сложнее:
>* каждый компонент (база, бекенд, фронтенд) запускаются в своем поде, регулируются отдельными deployment’ами;
>* для связи используются service (у каждого компонента свой);
>* в окружении фронта прописан адрес сервиса бекенда;
>* в окружении бекенда прописан адрес сервиса базы данных.

**Ответ**:

### Шаг 1. 


## ~Задание 3 (*): добавить endpoint на внешний ресурс api~
>Приложению потребовалось внешнее api, и для его использования лучше добавить endpoint в кластер, направленный на это api. Требования:
>* добавлен endpoint до внешнего api (например, геокодер).
