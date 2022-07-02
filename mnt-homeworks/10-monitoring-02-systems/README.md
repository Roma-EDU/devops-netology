# 10.2. Системы мониторинга

## 1. Опишите основные плюсы и минусы pull и push систем мониторинга.

**Pull**:
1. Плюсы
   * Можно конфигурировать всё в одном месте
   * Не обязательны агенты
   * Можно забирать данные когда угодно и куда угодно
   * Легко контролировать подлинность данных
2. Минусы
   * Более требователен к ресурсам (т.к. надо сходить всех опростить)
   * В случае падения системы сбора данных, метрику с хостов можно и потерять
   * Нужно знать адреса всех хостов, откуда собирать данные. А их много и могут добавляться/исключаться с течением времени

**Push**:
1. Плюсы
   * Можно быстрее отправлять данные (по UDP)
   * Легко динамически изменять агентов
   * Легко настраивать, какие данные с хоста будут отправлены 
2. Минусы
   * Каждый агент может слать, что ему угодно. Соответственно сложно с этим разбираться
   * Могут приходить недостоверные данные
   * Перенастроить множество агентов - сложно


## 2. Какие из ниже перечисленных систем относятся к push модели, а какие к pull? А может есть гибридные?

- Prometheus - pull + есть pushgateway для push
- TICK - push
- Zabbix - push и pull
- VictoriaMetrics - push и push
- Nagios - push и pull


## 3. TICK

>Склонируйте себе [репозиторий](https://github.com/influxdata/sandbox/tree/master) и запустите TICK-стэк, используя технологии docker и docker-compose.
>
>В виде решения на это упражнение приведите выводы команд с вашего компьютера (виртуальной машины):
>
>    - curl http://localhost:8086/ping
>    - curl http://localhost:8888
>    - curl http://localhost:9092/kapacitor/v1/ping
>
>А также скриншот веб-интерфейса ПО chronograf (`http://localhost:8888`). 
>
>P.S.: если при запуске некоторые контейнеры будут падать с ошибкой - проставьте им режим `Z`, например `./data:/var/lib:Z`

### Шаг 0. Добавил в Vagrantfile проброску портов

```ruby
config.vm.network "forwarded_port", guest: 8888, host: 8888
config.vm.network "forwarded_port", guest: 3010, host: 3010
```

### Шаг 1. Склонировал репозиторий и запустил установку

```bash
$ ./sandbox up
Using latest, stable releases
Spinning up Docker Images...
If this is your first time starting sandbox this might take a minute...
Creating network "tick_default" with the default driver
Building influxdb
Sending build context to Docker daemon  4.096kB
Step 1/2 : ARG INFLUXDB_TAG
Step 2/2 : FROM influxdb:$INFLUXDB_TAG
...
```

### Шаг 2. Смотрим, что получилось

```bash
$ curl http://localhost:8086/ping
$ curl http://localhost:8888
<!DOCTYPE html><html><head><meta http-equiv="Content-type" content="text/html; charset=utf-8"><title>Chronograf</title><link rel="icon shortcut" href="/favicon.fa749080.ico"><link rel="stylesheet" href="/src.9cea3e4e.css"></head><body> <div id="react-root" data-basepath=""></div> <script src="/src.a969287c.js"></script> </body></html>
$ curl http://localhost:9092/kapacitor/v1/ping
```

![image](https://user-images.githubusercontent.com/77544263/175807209-f375dd6b-5496-4b69-b17a-ca71a8e30c14.png)


## 4. Chronograf

>Перейдите в веб-интерфейс Chronograf (`http://localhost:8888`) и откройте вкладку `Data explorer`.
>
>    - Нажмите на кнопку `Add a query`
>    - Изучите вывод интерфейса и выберите БД `telegraf.autogen`
>    - В `measurments` выберите mem->host->telegraf_container_id , а в `fields` выберите used_percent. 
>    Внизу появится график утилизации оперативной памяти в контейнере telegraf.
>    - Вверху вы можете увидеть запрос, аналогичный SQL-синтаксису. 
>    Поэкспериментируйте с запросом, попробуйте изменить группировку и интервал наблюдений.
>
>Для выполнения задания приведите скриншот с отображением метрик утилизации места на диске 
>(disk->host->telegraf_container_id) из веб-интерфейса.

### Шаг 1. Дополняем собираемые метрики

Редактируем конфигурационный файл /telegraf/telegraf.conf, добавляя недостающие метрики
```conf
[[inputs.mem]]
[[inputs.disk]]
```

Перезапускаем для чтения актуальной конфигурации

```bash
$ ./sandbox restart
```

### Шаг 2. Смотрим, что получилось

![image](https://user-images.githubusercontent.com/77544263/175809828-4fb57696-3148-4c96-a75b-5a61bd68c948.png)


## 5. Telegraf

>Изучите список [telegraf inputs](https://github.com/influxdata/telegraf/tree/master/plugins/inputs). 
>Добавьте в конфигурацию telegraf следующий плагин - [docker](https://github.com/influxdata/telegraf/tree/master/plugins/inputs/docker):
>```
>[[inputs.docker]]
>  endpoint = "unix:///var/run/docker.sock"
>```
>
>Дополнительно вам может потребоваться донастройка контейнера telegraf в `docker-compose.yml` дополнительного volume и режима privileged:
>```
>  telegraf:
>    image: telegraf:1.4.0
>    privileged: true
>    volumes:
>      - ./etc/telegraf.conf:/etc/telegraf/telegraf.conf:Z
>      - /var/run/docker.sock:/var/run/docker.sock:Z
>    links:
>      - influxdb
>    ports:
>      - "8092:8092/udp"
>      - "8094:8094"
>      - "8125:8125/udp"
>```
>
>После настройке перезапустите telegraf, обновите веб интерфейс и приведите скриншотом список `measurments` в веб-интерфейсе базы telegraf.autogen . Там должны появиться метрики, связанные с docker.
>
>Факультативно можете изучить какие метрики собирает telegraf после выполнения данного задания.

### Шаг 1. Метрики для докера

Настройка метрик мониторинга докера уже есть изначально

```
[[inputs.docker]]
  endpoint = "unix:///var/run/docker.sock"
  container_names = []
  timeout = "5s"
  perdevice = true
  total = false
```

Но к сожалению метрики не появляются в интерфейсе. Пробовал разные настройки [из документации] (https://github.com/influxdata/telegraf/blob/master/plugins/inputs/docker/README.md#docker-daemon-permissions): привилегированный режим :Z, добавление пользователя telegraf (которого нет), не помогло

![image](https://user-images.githubusercontent.com/77544263/175812170-cc9924f6-fd7b-4a07-aea1-e5e9aca74584.png)

### Шаг 2. Метрики для докера - проверка telegraf

Подключился к контейнеру telegraf'a
```bash
$ ./sandbox enter telegraf
Using latest, stable releases
Entering /bin/bash session in the telegraf container...
```

Проверил доступы к сокету докера (выдавал права `chmod o+r /var/run/docker.sock`)
```bash
$ ls -la /var/run/docker.sock
srw-rw-r-- 1 root 998 0 Jul  2 08:10 /var/run/docker.sock
```

Проверил работу telegraf
```bash
$ telegraf --test
2022-07-02T10:34:19Z I! Using config file: /etc/telegraf/telegraf.conf
2022-07-02T10:34:19Z W! DeprecationWarning: Option "perdevice" of plugin "inputs.docker" deprecated since version 1.18.0 and will be removed in 2.0.0: use 'perdevice_include' instead
2022-07-02T10:34:19Z I! Starting Telegraf 1.23.0
2022-07-02T10:34:19Z I! Loaded inputs: cpu disk docker influxdb mem syslog system
2022-07-02T10:34:19Z I! Loaded aggregators:
2022-07-02T10:34:19Z I! Loaded processors:
2022-07-02T10:34:19Z W! Outputs are not used in testing mode!
2022-07-02T10:34:19Z I! Tags enabled: host=telegraf-getting-started
2022-07-02T10:34:19Z W! Deprecated inputs: 0 and 1 options
2022-07-02T10:34:19Z E! [agent] Starting input inputs.syslog: listen tcp 127.0.0.1:6514: bind: address already in use
...
```
Все ожидаемые метрики показываются (cpu disk **docker** influxdb mem syslog system), полный output в [telegraf-test.txt](./telegraf-test.txt) 


## ~Дополнительное задание (со звездочкой*) - необязательно к выполнению~

>В веб-интерфейсе откройте вкладку `Dashboards`. Попробуйте создать свой dashboard с отображением:
>
>    - утилизации ЦПУ
>    - количества использованного RAM
>    - утилизации пространства на дисках
>    - количество поднятых контейнеров
>    - аптайм
>    - ...
>    - фантазируйте)
