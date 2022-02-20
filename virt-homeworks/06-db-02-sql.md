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

**Ответ**

### Шаг 0. Подключаемся к контейнеру

Подключаемся к контейнеру и переходим в системную учётку postgres
```bash
$ docker exec -ti postgres_container /bin/bash
# su - postgres
```

### Шаг 1. Создаём БД и пользователя

```bash
$ createdb test_db
$ createuser test-admin-user
$ psql -c 'grant all privileges on database test_db to "test-admin-user";'
GRANT
```

### Шаг 2. Создаём таблицы согласно спецификации

Переходим в "консоль" базы данных, создаём таблицы и индекс, затем выходим из неё
```bash
$ psql -d test_db
test_db=# CREATE TABLE orders (
    id serial primary key,
    name varchar(255) NOT NULL,
    price int NOT NULL);
CREATE TABLE
test_db=# CREATE TABLE clients (
    id serial primary key,
    fio varchar(255) NOT NULL,
    country varchar(255), 
    orderId int REFERENCES orders);
CREATE TABLE
test_db=# CREATE INDEX idx_clients_country ON clients (country);
CREATE INDEX
test_db=# \q
```

### Шаг 3. Предоставление привилегий на всё

Даём пользователю ``test-admin-user`` права на любые действия с БД ``test_db``
```bash
$ psql -c 'grant all privileges on database test_db to "test-admin-user";'
GRANT
$ psql -c 'GRANT ALL ON orders, clients TO "test-admin-user";'
GRANT
```

### Шаг 4. Создаём подпользователя

```bash
$ createuser test-simple-user
```

### Шаг 5. Выдаём ограниченные права

```bash
$ psql -d test_db
psql (12.10 (Debian 12.10-1.pgdg110+1))
Type "help" for help.

test_db=# GRANT SELECT, INSERT, UPDATE, DELETE ON orders, clients TO "test-simple-user";
GRANT
test_db-# \q
```

### Шаг 6. Проверяем всё

```bash
$ psql -d test_db
psql (12.10 (Debian 12.10-1.pgdg110+1))
Type "help" for help.

test_db=# \dt
             List of relations
 Schema |  Name   | Type  |      Owner
--------+---------+-------+-----------------
 public | clients | table | postgres
 public | orders  | table | test-admin-user
(2 rows)

test_db=# \d orders
                                    Table "public.orders"
 Column |          Type          | Collation | Nullable |              Default
--------+------------------------+-----------+----------+------------------------------------
 id     | integer                |           | not null | nextval('orders_id_seq'::regclass)
 name   | character varying(255) |           | not null |
 price  | integer                |           | not null |
Indexes:
    "orders_pkey" PRIMARY KEY, btree (id)
Referenced by:
    TABLE "clients" CONSTRAINT "clients_orderid_fkey" FOREIGN KEY (orderid) REFERENCES orders(id)

test_db=# \d clients
                                    Table "public.clients"
 Column  |          Type          | Collation | Nullable |               Default
---------+------------------------+-----------+----------+-------------------------------------
 id      | integer                |           | not null | nextval('clients_id_seq'::regclass)
 fio     | character varying(255) |           | not null |
 country | character varying(255) |           |          |
 orderid | integer                |           |          |
Indexes:
    "clients_pkey" PRIMARY KEY, btree (id)
    "idx_clients_country" btree (country)
Foreign-key constraints:
    "clients_orderid_fkey" FOREIGN KEY (orderid) REFERENCES orders(id)

test_db=# SELECT * FROM information_schema.table_privileges WHERE grantee IN ('test-admin-user', 'test-simple-user');
     grantor     |     grantee      | table_catalog | table_schema | table_name | privilege_type | is_grantable | with_hierarchy
-----------------+------------------+---------------+--------------+------------+----------------+--------------+----------------
 test-admin-user | test-admin-user  | test_db       | public       | orders     | INSERT         | YES          | NO
 test-admin-user | test-admin-user  | test_db       | public       | orders     | SELECT         | YES          | YES
 test-admin-user | test-admin-user  | test_db       | public       | orders     | UPDATE         | YES          | NO
 test-admin-user | test-admin-user  | test_db       | public       | orders     | DELETE         | YES          | NO
 test-admin-user | test-admin-user  | test_db       | public       | orders     | TRUNCATE       | YES          | NO
 test-admin-user | test-admin-user  | test_db       | public       | orders     | REFERENCES     | YES          | NO
 test-admin-user | test-admin-user  | test_db       | public       | orders     | TRIGGER        | YES          | NO
 test-admin-user | test-simple-user | test_db       | public       | orders     | INSERT         | NO           | NO
 test-admin-user | test-simple-user | test_db       | public       | orders     | SELECT         | NO           | YES
 test-admin-user | test-simple-user | test_db       | public       | orders     | UPDATE         | NO           | NO
 test-admin-user | test-simple-user | test_db       | public       | orders     | DELETE         | NO           | NO
 postgres        | test-simple-user | test_db       | public       | clients    | INSERT         | NO           | NO
 postgres        | test-simple-user | test_db       | public       | clients    | SELECT         | NO           | YES
 postgres        | test-simple-user | test_db       | public       | clients    | UPDATE         | NO           | NO
 postgres        | test-simple-user | test_db       | public       | clients    | DELETE         | NO           | NO
 postgres        | test-admin-user  | test_db       | public       | clients    | INSERT         | NO           | NO
 postgres        | test-admin-user  | test_db       | public       | clients    | SELECT         | NO           | YES
 postgres        | test-admin-user  | test_db       | public       | clients    | UPDATE         | NO           | NO
 postgres        | test-admin-user  | test_db       | public       | clients    | DELETE         | NO           | NO
 postgres        | test-admin-user  | test_db       | public       | clients    | TRUNCATE       | NO           | NO
 postgres        | test-admin-user  | test_db       | public       | clients    | REFERENCES     | NO           | NO
 postgres        | test-admin-user  | test_db       | public       | clients    | TRIGGER        | NO           | NO
(22 rows)

```


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

**Ответ**

### Шаг 1. Наполняем таблицы данными

```sql
test_db=# INSERT INTO orders (name, price) VALUES ('Шоколад', 10), ('Принтер', 3000), ('Книга', 500), ('Монитор', 7000), ('Гитара', 4000);
INSERT 0 5
test_db=# INSERT INTO clients (fio, country) VALUES ('Иванов Иван Иванович', 'USA'), ('Петров Петр Петрович', 'Canada'), ('Иоганн Себастьян Бах', 'Japan'), ('Ронни Джеймс Дио', 'Russia'), ('Ritchie Blackmore', 'Russia');
INSERT 0 5
```

### Шаг 2. Просматриваем количество записей

```sql
test_db=# SELECT COUNT(*) FROM orders;
 count
-------
     5
(1 row)

test_db=# SELECT COUNT(*) FROM clients;
 count
-------
     5
(1 row)

```

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

**Ответ**

### Шаг 1. Обновляем записи в таблице

```sql
test_db=# UPDATE clients SET orderId = 3 WHERE id = 1;
UPDATE 1
test_db=# UPDATE clients SET orderId = 4 WHERE id = 2;
UPDATE 1
test_db=# UPDATE clients SET orderId = 5 WHERE id = 3;
UPDATE 1
```

### Шаг 2. Смотрим всех пользователей, которые совершили заказ

Два варианта: либо только пользователи (запрос проще и быстрее), либо вместе с заказом (запрос чуть тяжелее, зато нагляднее)
```sql
test_db=# SELECT id, fio FROM clients WHERE orderId IS NOT NULL;
 id |                  fio
----+----------------------------------------
  1 | Иванов Иван Иванович
  2 | Петров Петр Петрович
  3 | Иоганн Себастьян Бах
(3 rows)

test_db=# SELECT c.id, c.fio, o.name FROM clients c JOIN orders o ON c.orderId = o.id;
 id |                  fio                   |      name
----+----------------------------------------+----------------
  1 | Иванов Иван Иванович | Книга
  2 | Петров Петр Петрович | Монитор
  3 | Иоганн Себастьян Бах | Гитара
(3 rows)

```

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
