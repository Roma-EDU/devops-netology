# 14.1. Создание и использование секретов

## Задача 1: Работа с секретами через утилиту kubectl в установленном minikube

>Выполните приведённые ниже команды в консоли, получите вывод команд. Сохраните
>задачу 1 как справочный материал.
>
>### Как создать секрет?
>
>```
>openssl genrsa -out cert.key 4096
>openssl req -x509 -new -key cert.key -days 3650 -out cert.crt \
>-subj '/C=RU/ST=Moscow/L=Moscow/CN=server.local'
>kubectl create secret tls domain-cert --cert=certs/cert.crt --key=certs/cert.key
>```
>
>### Как просмотреть список секретов?
>
>```
>kubectl get secrets
>kubectl get secret
>```
>
>### Как просмотреть секрет?
>
>```
>kubectl get secret domain-cert
>kubectl describe secret domain-cert
>```
>
>### Как получить информацию в формате YAML и/или JSON?
>
>```
>kubectl get secret domain-cert -o yaml
>kubectl get secret domain-cert -o json
>```
>
>### Как выгрузить секрет и сохранить его в файл?
>
>```
>kubectl get secrets -o json > secrets.json
>kubectl get secret domain-cert -o yaml > domain-cert.yml
>```
>
>### Как удалить секрет?
>
>```
>kubectl delete secret domain-cert
>```
>
>### Как загрузить секрет из файла?
>
>```
>kubectl apply -f domain-cert.yml
>```

### Шаг 1. Создание секрета

Создадим с помощью `openssl` новые ключ `cert.key` и сертификат `cert.crt` (название обязательно такое для Kubernates) в папочке certs
```bash
$ mkdir certs
$ cd certs/
$ openssl genrsa -out cert.key 4096
Generating RSA private key, 4096 bit long modulus (2 primes)
.........................................................................................++++
................................++++
e is 65537 (0x010001)
$ openssl req -x509 -new -key cert.key -days 3650 -out cert.crt -subj '/C=RU/ST=Moscow/L=Moscow/CN=server.local'
$ cd ..
$ ls certs/
cert.crt  cert.key
```

И создадим новый секрет в Kubernates
```bash
$ kubectl create secret tls domain-cert --cert=certs/cert.crt --key=certs/cert.key
secret/domain-cert created
```


### Шаг 2. Просмотр списка секретов и подробностей об одном из них

Получить секреты можно с помощью команды `kubectl get secrets` или `kubectl get secret`
```bash
$ kubectl get secrets
NAME                                            TYPE                                  DATA   AGE
default-token-zv9bw                             kubernetes.io/service-account-token   3      5d10h
domain-cert                                     kubernetes.io/tls                     2      15s
nfs-server-nfs-server-provisioner-token-vk44d   kubernetes.io/service-account-token   3      5d9h
sh.helm.release.v1.nfs-server.v1                helm.sh/release.v1                    1      5d9h
$ kubectl get secret
NAME                                            TYPE                                  DATA   AGE
default-token-zv9bw                             kubernetes.io/service-account-token   3      5d10h
domain-cert                                     kubernetes.io/tls                     2      26s
nfs-server-nfs-server-provisioner-token-vk44d   kubernetes.io/service-account-token   3      5d9h
sh.helm.release.v1.nfs-server.v1                helm.sh/release.v1                    1      5d9h
```

Просмотреть конкретный секрет
```bash
$ kubectl get secret domain-cert
NAME          TYPE                DATA   AGE
domain-cert   kubernetes.io/tls   2      46s
$ kubectl describe secret domain-cert
Name:         domain-cert
Namespace:    prod
Labels:       <none>
Annotations:  <none>

Type:  kubernetes.io/tls

Data
====
tls.crt:  1944 bytes
tls.key:  3247 bytes
```


### Шаг 3. Выгрузка секрета в YAML и JSON

```
$ kubectl get secret domain-cert -o yaml
apiVersion: v1
data:
  tls.crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FUR ...
  tls.key: LS0tLS1CRUdJTiBSU0EgUFJJVkFUR ...
kind: Secret
metadata:
  creationTimestamp: "2022-11-11T20:06:40Z"
  name: domain-cert
  namespace: prod
  resourceVersion: "280392"
  uid: 58d02673-9c0e-4bc9-b898-296b809b12c7
type: kubernetes.io/tls
$ kubectl get secret domain-cert -o json
{
    "apiVersion": "v1",
    "data": {
        "tls.crt": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FUR ...",
        "tls.key": "LS0tLS1CRUdJTiBSU0EgUFJJVkFUR ..."
    },
    "kind": "Secret",
    "metadata": {
        "creationTimestamp": "2022-11-11T20:06:40Z",
        "name": "domain-cert",
        "namespace": "prod",
        "resourceVersion": "280392",
        "uid": "58d02673-9c0e-4bc9-b898-296b809b12c7"
    },
    "type": "kubernetes.io/tls"
}
```


### Шаг 4. Выгрузка секретов в файл

```
$ kubectl get secrets -o json > secrets.json
$ kubectl get secret domain-cert -o yaml > domain-cert.yml
$ ls -la
total 52
drwxrwxrwx 1 vagrant vagrant  4096 Nov 11 20:26 .
drwxrwxrwx 1 vagrant vagrant  4096 Nov 11 20:01 ..
drwxrwxrwx 1 vagrant vagrant     0 Nov 11 20:05 certs
-rwxrwxrwx 1 vagrant vagrant  7170 Nov 11 20:08 domain-cert.yml
-rwxrwxrwx 1 vagrant vagrant 36455 Nov 11 20:08 secrets.json
```


### Шаг 5. Удаление секрета

```
$ kubectl delete secret domain-cert
secret "domain-cert" deleted
$ kubectl get secrets
NAME                                            TYPE                                  DATA   AGE
default-token-zv9bw                             kubernetes.io/service-account-token   3      5d10h
nfs-server-nfs-server-provisioner-token-vk44d   kubernetes.io/service-account-token   3      5d9h
sh.helm.release.v1.nfs-server.v1                helm.sh/release.v1                    1      5d9h
```


### Шаг 6. Создание секрета из файла

```
$ kubectl apply -f domain-cert.yml
secret/domain-cert created
$ kubectl get secrets
NAME                                            TYPE                                  DATA   AGE
default-token-zv9bw                             kubernetes.io/service-account-token   3      5d10h
domain-cert                                     kubernetes.io/tls                     2      4s
nfs-server-nfs-server-provisioner-token-vk44d   kubernetes.io/service-account-token   3      5d9h
sh.helm.release.v1.nfs-server.v1                helm.sh/release.v1                    1      5d9h
```

При этом содержимое файла
```yaml
apiVersion: v1
data:
  tls.crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FUR ... SOME MORE DATA ...
  tls.key: LS0tLS1CRUdJTiBSU0EgUFJJVkFUR ... SOME MORE DATA ...
kind: Secret
metadata:
  creationTimestamp: "2022-11-11T20:06:40Z"
  name: domain-cert
  namespace: prod
  resourceVersion: "280392"
  uid: 58d02673-9c0e-4bc9-b898-296b809b12c7
type: kubernetes.io/tls
```

## ~Задача 2 (*): Работа с секретами внутри модуля~

>Выберите любимый образ контейнера, подключите секреты и проверьте их доступность
>как в виде переменных окружения, так и в виде примонтированного тома.

### Шаг 1. Использование в виде переменных окружения

Подробности в [документации](https://kubernetes.io/docs/tasks/inject-data-application/distribute-credentials-secure/)

Создадим секреты (имя пользователя и пароль)
```bash
$ kubectl create secret generic my-secret --from-literal=user-name='my-user' --from-literal=password='pwd123'
```

И воспользуемся ими через переменные окружения
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: env-secrets-pod
spec:
  containers:
  - name: nginx
    image: nginx:latest
    env:
    - name: DB_USERNAME
      valueFrom:
        secretKeyRef:
          name: my-secret
          key: user-name
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: my-secret
          key: password
```


### Шаг 2. Использование в виде примонтированного тома

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
spec:
  containers:
  - name: nginx
    image: nginx:latest
    ports:
    - containerPort: 80
      protocol: TCP
    - containerPort: 443
      protocol: TCP
    volumeMounts:
    - name: certs
      mountPath: "/etc/nginx/ssl"
      readOnly: true
    - name: config
      mountPath: /etc/nginx/conf.d
      readOnly: true
  volumes:
  - name: certs
    secret:
      secretName: domain-cert
  - name: config
    configMap:
    name: nginx-config
```
