# 6.5. Elasticsearch

## Задача 1

Используя докер образ [centos:7](https://hub.docker.com/_/centos) как базовый и 
[документацию по установке и запуску Elastcisearch](https://www.elastic.co/guide/en/elasticsearch/reference/current/targz.html):

- составьте Dockerfile-манифест для elasticsearch
- соберите docker-образ и сделайте `push` в ваш docker.io репозиторий
- запустите контейнер из получившегося образа и выполните запрос пути `/` c хост-машины

Требования к `elasticsearch.yml`:
- данные `path` должны сохраняться в `/var/lib`
- имя ноды должно быть `netology_test`

В ответе приведите:
- текст Dockerfile манифеста
- ссылку на образ в репозитории dockerhub
- ответ `elasticsearch` на запрос пути `/` в json виде

Подсказки:
- возможно вам понадобится установка пакета perl-Digest-SHA для корректной работы пакета shasum
- при сетевых проблемах внимательно изучите кластерные и сетевые настройки в elasticsearch.yml
- при некоторых проблемах вам поможет docker директива ulimit
- elasticsearch в логах обычно описывает проблему и пути ее решения

Далее мы будем работать с данным экземпляром elasticsearch.

**Ответ**

### Шаг 0*. Подготовка

Уже есть готовые настроенные docker-образы от разработчиков эластика. Если они нам подходят - не мучаемся и берём их.

### Шаг 1. Пишем конфигурационный файл

Конфигурационный файл для elasticsearch `elasticsearch.yml`
Запоминаем пути, т.к. они будут использованы в Dockerfile-манифесте
Отключаем xpack.security, иначе после запуска контейнера нужно выполнять сброс пароля и выполнять аутентификацию.
Прописываем network.host: 0.0.0.0, чтобы можно было достучаться снаружи контейнера

```yml
node:
    name: netology_test     # Название ноды

cluster:
    name: es_cluster                # Название кластера

path:
    data: /var/lib                  # Путь для хранения данных
    logs: /var/log/elasticsearch    # Путь для хранения логов
    repo: /usr/share/elasticsearch/snapshots # Директория со снепшотами

network.host: 0.0.0.0
discovery.type: single-node # Режим работы - одна нода

xpack.security.enabled: false
xpack.security.transport.ssl.enabled: false
```

### Шаг 2. Пишем Dockerfile-манифест

```
FROM    centos:7
ARG		  version=7.17.1
ENV		  ES_HOME=/usr/share/elasticsearch ES_PATH_CONF=/usr/share/elasticsearch/config/

RUN     yum update -y && \ 
        yum install wget -y && \
		    wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-$version-linux-x86_64.tar.gz && \
		    wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-$version-linux-x86_64.tar.gz.sha512 && \
		    sha512sum --check elasticsearch-$version-linux-x86_64.tar.gz.sha512 && \
		    tar -xzf elasticsearch-$version-linux-x86_64.tar.gz && \
		    rm elasticsearch-$version-linux-x86_64.tar.gz -f && \
		    rm elasticsearch-$version-linux-x86_64.tar.gz.sha512 -f && \
		    mv elasticsearch-$version $ES_HOME

COPY    elasticsearch.yml $ES_PATH_CONF/elasticsearch.yml

RUN     groupadd -g 1000 elasticsearch && \
		    useradd elasticsearch -u 1000 -g 1000 && \
		    chown -R elasticsearch:elasticsearch $ES_HOME && \
		    mkdir /var/log/elasticsearch && \
		    chmod 777 /var/log/elasticsearch && \
		    chmod 777 /var/lib/

USER    elasticsearch

EXPOSE  9200 9300

CMD     ["/usr/share/elasticsearch/bin/elasticsearch"]
```

### Шаг 3. Сборка образа и запуск

Переходим в рабочую папку с проборошенными файликами из предыдущих шагов и запускаем сборку `sudo docker build -t roma4edu/netology_elasticsearch:0.1 .` (не забывая точку на конце). 
```bash
$ cd /vagrant/06-db-05-elasticsearch
$ sudo docker build -t roma4edu/netology_elasticsearch:0.1 .
Sending build context to Docker daemon  9.728kB
Step 1/9 : FROM    centos:7
 ---> eeb6ee3f44bd
...
Step 9/9 : CMD     ["/usr/share/elasticsearch/bin/elasticsearch"]
 ---> Running in e14904db153b
Removing intermediate container e14904db153b
 ---> 32ac4972a617
Successfully built 32ac4972a617
Successfully tagged roma4edu/netology_elasticsearch:0.1
```

После завершения сборки запускаем получившийся образ с проброской портов и в состоянии detach (флаг `-d`) и проверяем работоспособность. Между запуском и вызовом curl надо подождать (пока выполняется инициализация)
```bash
$ sudo docker run --name elastic -p 9200:9200 -p 9300:9300 -d roma4edu/netology_elasticsearch:0.1
1514c9db949262538e89d152a35c9edda1021944aa1e355d4c6d6d6876a9fefc
$ curl http://localhost:9200
{
  "name" : "netology_test",
  "cluster_name" : "es_cluster",
  "cluster_uuid" : "1lRu94ofRxeHxE0EW8vqKg",
  "version" : {
    "number" : "7.17.1",
    "build_flavor" : "default",
    "build_type" : "tar",
    "build_hash" : "e5acb99f822233d62d6444ce45a4543dc1c8059a",
    "build_date" : "2022-02-23T22:20:54.153567231Z",
    "build_snapshot" : false,
    "lucene_version" : "8.11.1",
    "minimum_wire_compatibility_version" : "6.8.0",
    "minimum_index_compatibility_version" : "6.0.0-beta1"
  },
  "tagline" : "You Know, for Search"
}
```

### Шаг 4. Заливка образа в репозиторий

Останавливаем все образы, логинимся в https://hub.docker.com и заливаем образ в свой [репозиторий](https://hub.docker.com/repository/docker/roma4edu/netology_elasticsearch)
```bash
$ sudo -i
$ docker stop $(docker ps -a -q)
1514c9db9492
$ docker login -u roma4edu
Password:
Login Succeeded
$ docker push roma4edu/netology_elasticsearch:0.1
The push refers to repository [docker.io/roma4edu/netology_elasticsearch]
33fee0116ed3: Pushed
3e6f56ba1d15: Pushed
673384738372: Pushed
174f56854903: Mounted from library/centos
0.1: digest: sha256:2d7871136e13004a5b35cfd6eb201ca9e4190edd47c1fe09a63c44a4d0873805 size: 1162
```

## Задача 2

В этом задании вы научитесь:
- создавать и удалять индексы
- изучать состояние кластера
- обосновывать причину деградации доступности данных

Ознакомтесь с [документацией](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-create-index.html) 
и добавьте в `elasticsearch` 3 индекса, в соответствии со таблицей:

| Имя | Количество реплик | Количество шард |
|-----|-------------------|-----------------|
| ind-1| 0 | 1 |
| ind-2 | 1 | 2 |
| ind-3 | 2 | 4 |

Получите список индексов и их статусов, используя API и **приведите в ответе** на задание.

Получите состояние кластера `elasticsearch`, используя API.

Как вы думаете, почему часть индексов и кластер находится в состоянии yellow?

Удалите все индексы.

**Важно**

При проектировании кластера elasticsearch нужно корректно рассчитывать количество реплик и шард,
иначе возможна потеря данных индексов, вплоть до полной, при деградации системы.

## Задача 3

В данном задании вы научитесь:
- создавать бэкапы данных
- восстанавливать индексы из бэкапов

Создайте директорию `{путь до корневой директории с elasticsearch в образе}/snapshots`.

Используя API [зарегистрируйте](https://www.elastic.co/guide/en/elasticsearch/reference/current/snapshots-register-repository.html#snapshots-register-repository) 
данную директорию как `snapshot repository` c именем `netology_backup`.

**Приведите в ответе** запрос API и результат вызова API для создания репозитория.

Создайте индекс `test` с 0 реплик и 1 шардом и **приведите в ответе** список индексов.

[Создайте `snapshot`](https://www.elastic.co/guide/en/elasticsearch/reference/current/snapshots-take-snapshot.html) 
состояния кластера `elasticsearch`.

**Приведите в ответе** список файлов в директории со `snapshot`ами.

Удалите индекс `test` и создайте индекс `test-2`. **Приведите в ответе** список индексов.

[Восстановите](https://www.elastic.co/guide/en/elasticsearch/reference/current/snapshots-restore-snapshot.html) состояние
кластера `elasticsearch` из `snapshot`, созданного ранее. 

**Приведите в ответе** запрос к API восстановления и итоговый список индексов.

Подсказки:
- возможно вам понадобится доработать `elasticsearch.yml` в части директивы `path.repo` и перезапустить `elasticsearch`
