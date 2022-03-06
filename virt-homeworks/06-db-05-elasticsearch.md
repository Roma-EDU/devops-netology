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
Предполагается, что на машине уже стоит docker, если нет, то ставим

### Шаг 1. Пишем конфигурационный файл

Конфигурационный файл для elasticsearch `elasticsearch.yml`:
* Запоминаем пути, т.к. они будут использованы в Dockerfile-манифесте
* Отключаем `xpack.security`, иначе после запуска контейнера нужно выполнять сброс пароля и выполнять аутентификацию.
* Прописываем `network.host: 0.0.0.0`, чтобы можно было достучаться снаружи контейнера

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
ARG	version=7.17.1
ENV	ES_HOME=/usr/share/elasticsearch ES_PATH_CONF=/usr/share/elasticsearch/config/

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

**Ответ**

### Шаг 1. Создание индексов

Воспользуемся API 
```bash
$ curl -X PUT localhost:9200/ind-1 -H 'Content-Type: application/json' -d'{ "settings": { "number_of_shards": 1,  "number_of_replicas": 0 }}'
{"acknowledged":true,"shards_acknowledged":true,"index":"ind-1"}
$ curl -X PUT localhost:9200/ind-2 -H 'Content-Type: application/json' -d'{ "settings": { "number_of_shards": 2,  "number_of_replicas": 1 }}'
{"acknowledged":true,"shards_acknowledged":true,"index":"ind-2"}
$ curl -X PUT localhost:9200/ind-3 -H 'Content-Type: application/json' -d'{ "settings": { "number_of_shards": 4,  "number_of_replicas": 2 }}'
{"acknowledged":true,"shards_acknowledged":true,"index":"ind-3"}
```

### Шаг 2. Получение списка индексов и их статусов

```bash
$ curl -X GET 'http://localhost:9200/_cat/indices?v'
health status index            uuid                   pri rep docs.count docs.deleted store.size pri.store.size
green  open   .geoip_databases crEmAu7FTMm9FjPvx_VF4g   1   0         41            0     72.2mb         72.2mb
green  open   ind-1            nUiXJptBSXOy4laYtpmNvg   1   0          0            0       226b           226b
yellow open   ind-3            KvbAyrLPQ4GPLRc19i4Qeg   4   2          0            0       904b           904b
yellow open   ind-2            Rod_yShJTX-ZEtU2Y9qpEQ   2   1          0            0       452b           452b
```

Дополнительно можно посмотреть индексы поподробнее
```bash
curl -X GET 'http://localhost:9200/_cluster/health/ind-1?pretty'
{
  "cluster_name" : "es_cluster",
  "status" : "green",
  "timed_out" : false,
  "number_of_nodes" : 1,
  "number_of_data_nodes" : 1,
  "active_primary_shards" : 1,
  "active_shards" : 1,
  "relocating_shards" : 0,
  "initializing_shards" : 0,
  "unassigned_shards" : 0,
  "delayed_unassigned_shards" : 0,
  "number_of_pending_tasks" : 0,
  "number_of_in_flight_fetch" : 0,
  "task_max_waiting_in_queue_millis" : 0,
  "active_shards_percent_as_number" : 100.0
}
```

### Шаг 3. Получение состояния кластера

```bash
$ curl -XGET localhost:9200/_cluster/health/?pretty=true
{
  "cluster_name" : "es_cluster",
  "status" : "yellow",
  "timed_out" : false,
  "number_of_nodes" : 1,
  "number_of_data_nodes" : 1,
  "active_primary_shards" : 8,
  "active_shards" : 8,
  "relocating_shards" : 0,
  "initializing_shards" : 0,
  "unassigned_shards" : 10,
  "delayed_unassigned_shards" : 0,
  "number_of_pending_tasks" : 0,
  "number_of_in_flight_fetch" : 0,
  "task_max_waiting_in_queue_millis" : 0,
  "active_shards_percent_as_number" : 44.44444444444444
}

$ curl -X GET "localhost:9200/_cat/shards?pretty"
ind-2            1 p STARTED     0   226b 172.17.0.2 netology_test
ind-2            1 r UNASSIGNED
ind-2            0 p STARTED     0   226b 172.17.0.2 netology_test
ind-2            0 r UNASSIGNED
ind-3            3 p STARTED     0   226b 172.17.0.2 netology_test
ind-3            3 r UNASSIGNED
ind-3            3 r UNASSIGNED
ind-3            1 p STARTED     0   226b 172.17.0.2 netology_test
ind-3            1 r UNASSIGNED
ind-3            1 r UNASSIGNED
ind-3            2 p STARTED     0   226b 172.17.0.2 netology_test
ind-3            2 r UNASSIGNED
ind-3            2 r UNASSIGNED
ind-3            0 p STARTED     0   226b 172.17.0.2 netology_test
ind-3            0 r UNASSIGNED
ind-3            0 r UNASSIGNED
.geoip_databases 0 p STARTED    41 39.5mb 172.17.0.2 netology_test
ind-1            0 p STARTED     0   226b 172.17.0.2 netology_test

$ curl -X GET "localhost:9200/_cat/nodes"
172.17.0.2 23 95 0 0.00 0.01 0.13 cdfhilmrstw * netology_test
```

Часть индексов и кластер находится в состоянии yellow, потому что для индексов `ind-2` и `ind-3` реплики не размещены (находятся в статусе UNASSIGNED). Этого и следовало ожидать, так как размещать в кластере из 1 ноды реплики на других нодах невозможно.

### Шаг 4. Удаление индексов

Через API вызываем команду для удаления всех индексов, затем проверяем что ничего не осталось.
```bash
$ curl -XDELETE 'localhost:9200/_all'
{"acknowledged":true}

$ curl -X GET 'http://localhost:9200/_cat/indices?v'
health status index            uuid                   pri rep docs.count docs.deleted store.size pri.store.size
green  open   .geoip_databases crEmAu7FTMm9FjPvx_VF4g   1   0         41            0     39.5mb         39.5mb
```

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
