# 6.2. SQL

## Задача 1

Используя docker поднимите инстанс PostgreSQL (версию 12) c 2 volume, 
в который будут складываться данные БД и бэкапы.

Приведите получившуюся команду или docker-compose манифест.

**Ответ**:

### Шаг 0. Подготовка окружения

Устанавливаем docker
```bash
$ sudo apt update
Hit:1 http://archive.ubuntu.com/ubuntu focal InRelease
...
38 packages can be upgraded. Run 'apt list --upgradable' to see them.
$ sudo apt-get install ca-certificates curl gnupg lsb-release
Reading package lists... Done
...
0 upgraded, 0 newly installed, 0 to remove and 38 not upgraded.
$ curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
$ echo \
>   "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
>   $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
$ sudo apt-get update
Hit:1 http://archive.ubuntu.com/ubuntu focal InRelease
...
Reading package lists... Done
$ sudo apt-get install docker-ce docker-ce-cli containerd.io
Reading package lists... Done
...
After this operation, 409 MB of additional disk space will be used.
Do you want to continue? [Y/n] y
Get:1 http://archive.ubuntu.com/ubuntu focal/universe amd64 pigz amd64 2.4-1 [57.4 kB]
...
$ docker --version
Docker version 20.10.12, build e91ed57
```

И устанавливаем docker-compose
```bash
$ sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   664  100   664    0     0   3004      0 --:--:-- --:--:-- --:--:--  2990
100 12.1M  100 12.1M    0     0  2264k      0  0:00:05  0:00:05 --:--:-- 2720k
$ sudo chmod +x /usr/local/bin/docker-compose
$ docker-compose --version
docker-compose version 1.29.2, build 5becea4c
```

### Шаг 1. Создаём манифест

Примечания:
* Из-за того, что основная хост-машина работает на Windows, не удаётся смотировать volume 
с нужными правами в шаренной папке (в описании самого сервиса ``./database:/var/lib/postgresql/data``), 
поэтому создаём виртуальные volume в начале раздела
* В качестве POSTGRES_USER обязательно указать системную учётку "postgres", иначе половина команд для администрирования
(создание БД и учётки) будут завершаться с ошибкой, а другие - требовать указания -U other-user-name, что очень не удобно 

Сам docker-compose.yml
```yaml
version: "3.9"

networks:
  localnet:
    driver: bridge
    
volumes:
  pgdata_volume:
  backups_volume:

services:
  postgres_service:
    container_name: postgres_container
    image: postgres:12
    environment:
      POSTGRES_DB: "postgres_db"
      POSTGRES_USER: "postgres"
      POSTGRES_PASSWORD: "pwd4postgres"
      PGDATA: "/var/lib/postgresql/data/pgdata"
    volumes:
      - pgdata_volume:/var/lib/postgresql/data
      - backups_volume:/var/backups
    ports:
      - "5432:5432"
    restart: always
    networks:
      - localnet
```

### Шаг 2. Запускаем сервисы

Переходим в рабочую директорию (где лежит манифест docker-compose.yml) и запускаем сервисы (возможно из-под sudo) с ключиком -d (detached)
```bash
$ cd /vagrant/06-db-02-sql
$ docker-compose up -d
Starting postgres_container ... done
```


## Задача 2

В БД из задачи 1: 
- создайте пользователя test-admin-user и БД test_db
- в БД test_db создайте таблицу orders и clients (спeцификация таблиц ниже)
- предоставьте привилегии на все операции пользователю test-admin-user на таблицы БД test_db
- создайте пользователя test-simple-user  
- предоставьте пользователю test-simple-user права на SELECT/INSERT/UPDATE/DELETE данных таблиц БД test_db

Таблица orders:
- id (serial primary key)
- наименование (string)
- цена (integer)

Таблица clients:
- id (serial primary key)
- фамилия (string)
- страна проживания (string, index)
- заказ (foreign key orders)

Приведите:
- итоговый список БД после выполнения пунктов выше,
- описание таблиц (describe)
- SQL-запрос для выдачи списка пользователей с правами над таблицами test_db
- список пользователей с правами над таблицами test_db

## Задача 3

Используя SQL синтаксис - наполните таблицы следующими тестовыми данными:

Таблица orders

|Наименование|цена|
|------------|----|
|Шоколад| 10 |
|Принтер| 3000 |
|Книга| 500 |
|Монитор| 7000|
|Гитара| 4000|

Таблица clients

|ФИО|Страна проживания|
|------------|----|
|Иванов Иван Иванович| USA |
|Петров Петр Петрович| Canada |
|Иоганн Себастьян Бах| Japan |
|Ронни Джеймс Дио| Russia|
|Ritchie Blackmore| Russia|

Используя SQL синтаксис:
- вычислите количество записей для каждой таблицы 
- приведите в ответе:
    - запросы 
    - результаты их выполнения.

## Задача 4

Часть пользователей из таблицы clients решили оформить заказы из таблицы orders.

Используя foreign keys свяжите записи из таблиц, согласно таблице:

|ФИО|Заказ|
|------------|----|
|Иванов Иван Иванович| Книга |
|Петров Петр Петрович| Монитор |
|Иоганн Себастьян Бах| Гитара |

Приведите SQL-запросы для выполнения данных операций.

Приведите SQL-запрос для выдачи всех пользователей, которые совершили заказ, а также вывод данного запроса.
 
Подсказк - используйте директиву `UPDATE`.

## Задача 5

Получите полную информацию по выполнению запроса выдачи всех пользователей из задачи 4 
(используя директиву EXPLAIN).

Приведите получившийся результат и объясните что значат полученные значения.

## Задача 6

Создайте бэкап БД test_db и поместите его в volume, предназначенный для бэкапов (см. Задачу 1).

Остановите контейнер с PostgreSQL (но не удаляйте volumes).

Поднимите новый пустой контейнер с PostgreSQL.

Восстановите БД test_db в новом контейнере.

Приведите список операций, который вы применяли для бэкапа данных и восстановления. 
