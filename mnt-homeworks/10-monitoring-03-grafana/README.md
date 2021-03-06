# 10.3. Grafana

## ~Задание повышенной сложности~

>**В части задания 1** не используйте директорию [help](./help) для сборки проекта, самостоятельно разверните grafana, где в роли источника данных будет выступать prometheus, а сборщиком данных node-exporter:
>- grafana
>- prometheus-server
>- prometheus node-exporter
>
>За дополнительными материалами, вы можете обратиться в официальную документацию grafana и prometheus.
>
>В решении к домашнему заданию приведите также все конфигурации/скрипты/манифесты, которые вы использовали в процессе решения задания.

>**В части задания 3** вы должны самостоятельно завести удобный для вас канал нотификации, например Telegram или Email и отправить туда тестовые события.
>
>В решении приведите скриншоты тестовых событий из каналов нотификаций.

## Обязательные задания

### Задание 1
>Используя директорию [help](./help) внутри данного домашнего задания - запустите связку prometheus-grafana.
>
>Зайдите в веб-интерфейс графана, используя авторизационные данные, указанные в манифесте docker-compose.
>
>Подключите поднятый вами prometheus как источник данных.
>
>Решение домашнего задания - скриншот веб-интерфейса grafana со списком подключенных Datasource.

**Ответ**

1. Пробросил порт 3000
2. Скопировал содержимое папки help, перешёл в неё и запустил контейнер `$ docker-compose up`
3. Дождался завершения сборки, открыл в браузере веб-интерфейс grafana http://localhost:3000, авторизовался с помощью логина-пароля admin
4. Подключил prometeus в качестве Datasource с помощью [документации](https://grafana.com/tutorials/grafana-fundamentals/?utm_source=grafana_gettingstarted#add-a-metrics-data-source)
![image](https://user-images.githubusercontent.com/77544263/179374895-33c036da-8e5c-40b4-9aba-9cc7a5e8e55e.png)


## Задание 2
>Изучите самостоятельно ресурсы:
>- [promql-for-humans](https://timber.io/blog/promql-for-humans/#cpu-usage-by-instance)
>- [understanding prometheus cpu metrics](https://www.robustperception.io/understanding-machine-cpu-usage)
>
>Создайте Dashboard и в ней создайте следующие Panels:
>- Утилизация CPU для nodeexporter (в процентах, 100-idle)
>- CPULA 1/5/15
>- Количество свободной оперативной памяти
>- Количество места на файловой системе
>
>Для решения данного ДЗ приведите promql запросы для выдачи этих метрик, а также скриншот получившейся Dashboard.

**Ответ**

1. Утилизация CPU для nodeexporter (в процентах, 100-idle)
   - `100 * (1 - avg by(instance)(irate(node_cpu_seconds_total{job="nodeexporter",mode="idle"}[5m])))`
2. CPULA 1/5/15
   - `node_load1{job="nodeexporter"}`
   - `node_load5{job="nodeexporter"}`
   - `node_load15{job="nodeexporter"}`
3. Количество свободной оперативной памяти
   - `node_memory_MemFree_bytes{job="nodeexporter"} / (1024 * 1024)`
4. Количество места на файловой системе
   - `node_filesystem_free_bytes{job="nodeexporter",mountpoint="/"} / (1024 * 1024 * 1024)`

Скриншот - общий со следующим заданием с alert

## Задание 3
>Создайте для каждой Dashboard подходящее правило alert (можно обратиться к первой лекции в блоке "Мониторинг").
>
>Для решения ДЗ - приведите скриншот вашей итоговой Dashboard.

**Ответ**

Добавил alert'ы
1. CPU Usage - больше 25% (не видно на скрине)
2. CPU LA5 - больше 2 (т.к. по количеству ядер CPU: 2). Для LA1 не вижу смысла (резки скачки вполне могут случаться), а LA15 закроется LA5
3. RAM - поставил ограничение, что должно быть свободно не меньше 10%
4. Disk - не менее 20 Гб, просто чтобы было время в запасе

![image](https://user-images.githubusercontent.com/77544263/181388857-9ca5d5ee-3706-4371-a8f3-58d872fedf2a.png)


## Задание 4
>Сохраните ваш Dashboard.
>
>Для этого перейдите в настройки Dashboard, выберите в боковом меню "JSON MODEL".
>
>Далее скопируйте отображаемое json-содержимое в отдельный файл и сохраните его.
>
>В решении задания - приведите листинг этого файла.

**Ответ**: приложил [My-metrics.json](./My-metrics.json)
