# 6.4. PostgreSQL

## Задача 1

Используя docker поднимите инстанс PostgreSQL (версию 13). Данные БД сохраните в volume.

Подключитесь к БД PostgreSQL используя `psql`.

Воспользуйтесь командой `\?` для вывода подсказки по имеющимся в `psql` управляющим командам.

**Найдите и приведите** управляющие команды для:
- вывода списка БД
- подключения к БД
- вывода списка таблиц
- вывода описания содержимого таблиц
- выхода из psql

**Ответ**

### Шаг 1. Поднимаем контейнер с PostgreSQL

Пишем манифест docker-compose.yml
```yml
version: "3.9"

networks:
  localnet:
    driver: bridge
    
volumes:
  pgdata_volume:

services:
  postgres_service:
    container_name: postgres_container
    image: postgres:13
    environment:
      POSTGRES_DB: "postgres_db"
      POSTGRES_USER: "postgres"
      POSTGRES_PASSWORD: "pwd4postgres"
      PGDATA: "/var/lib/postgresql/data/pgdata"
    volumes:
      - pgdata_volume:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    restart: always
    networks:
      - localnet
```

И с помощью `docker-compose` запускаем контейнер согласно этому манифесту
```bash
$ cd /vagrant/06-db-04-postgresql
$ sudo docker-compose up -d
Creating network "06-db-04-postgresql_localnet" with driver "bridge"
Creating volume "06-db-04-postgresql_pgdata_volume" with default driver
Pulling postgres_service (postgres:13)...
13: Pulling from library/postgres
5eb5b503b376: Already exists
...
Starting postgres_container ... done
```

Заодно для задачи 2 закидываем в него бэкап `test_dump.sql` базы данных в папку, соответствующую "постоянному" `volume` (см. манифест pgdata_volume:/var/lib/postgresql/data)
```bash
$ sudo docker cp test_dump.sql postgres_container:/var/lib/postgresql/data/test_dump.sql
```

### Шаг 2. Подключаемся к БД

Подключаемся к развёрнутому контейнеру и переходим под пользователя `postgres` (тот который POSTGRES_USER: "postgres"). Затем вводим `psql` (без параметров, т.к. правильно назвали пользователя :))
```bash
$ sudo docker exec -ti postgres_container /bin/bash
$ su - postgres
postgres@ec9f6ef9c97d:~$ psql
psql (13.6 (Debian 13.6-1.pgdg110+1))
Type "help" for help.

```

### Шаг 3. Изучаем список доступных команд

С помощью `\?` (и потом стрелочки вниз) узнаём список доступных команд
```bash
postgres=# \?
General
  \copyright             show PostgreSQL usage and distribution terms
  \crosstabview [COLUMNS] execute query and display results in crosstab
  \errverbose            show most recent error message at maximum verbosity
  ...
```

Управляющие команды для:
- вывода списка БД `\db[+]  [PATTERN]      list tablespaces`
- подключения к БД `\c[onnect] {[DBNAME|- USER|- HOST|- PORT|-] | conninfo}      connect to new database (currently "postgres")`
- вывода списка таблиц `\dt[S+] [PATTERN]      list tables`
- вывода описания содержимого таблиц `\d[S+]  NAME           describe table, view, sequence, or index`
- выхода из psql `\q`

## Задача 2

Используя `psql` создайте БД `test_database`.

Изучите [бэкап БД](https://github.com/netology-code/virt-homeworks/tree/master/06-db-04-postgresql/test_data).

Восстановите бэкап БД в `test_database`.

Перейдите в управляющую консоль `psql` внутри контейнера.

Подключитесь к восстановленной БД и проведите операцию ANALYZE для сбора статистики по таблице.

Используя таблицу [pg_stats](https://postgrespro.ru/docs/postgresql/12/view-pg-stats), найдите столбец таблицы `orders` 
с наибольшим средним значением размера элементов в байтах.

**Приведите в ответе** команду, которую вы использовали для вычисления и полученный результат.

**Ответ**

### Шаг 1. Создаём БД

Поскольку мы всё ещё находимся в управляющей консоли `psql`, выполним создание БД `test_database` из неё и выйдем
```sql
postgres=# create database test_database;
CREATE DATABASE
postgres=# \q
```

### Шаг 2. Восстанавливаем бэкап

Находим относительный путь до .sql-бэкапа и восстанавливаем его в созданную на предыдущем шаге БД
```bash
$ pwd
/var/lib/postgresql
$ psql  test_database < ./data/test_dump.sql
SET
SET
SET
...
ALTER TABLE
```

### Шаг 3. Подключаемся к восстановленной БД и анализируем её

С помощью таблицы `pg_stats` узнаём, что в таблице `orders` больше всего отведено место для столбца `title` 
```sql
$ psql -d test_database
psql (13.6 (Debian 13.6-1.pgdg110+1))
Type "help" for help.

test_database=# ANALYZE;
ANALYZE
test_database=# SELECT attname, avg_width FROM pg_stats WHERE tablename = 'orders';
 attname | avg_width
---------+-----------
 id      |         4
 title   |        16
 price   |         4
(3 rows)
```


## Задача 3

Архитектор и администратор БД выяснили, что ваша таблица orders разрослась до невиданных размеров и
поиск по ней занимает долгое время. Вам, как успешному выпускнику курсов DevOps в нетологии предложили
провести разбиение таблицы на 2 (шардировать на orders_1 - price>499 и orders_2 - price<=499).

Предложите SQL-транзакцию для проведения данной операции.

Можно ли было изначально исключить "ручное" разбиение при проектировании таблицы orders?

**Ответ**

### Шаг 1. Создаём скрипт для разбивки таблицы на 2 части

Заводим переменную для удобства
```bash
test_database=# \set price_limit 499
```

и выполняем скрипт по разбивке таблицы `orders` на кусочки
(подсказка: последним шагом можно добавить SELECT'ы из интересующих нас таблиц и ROLLBACK вместо COMMIT. После отладки убрать лишнее и поставить COMMIT)
```sql
BEGIN;

-- Создаём партиции
CREATE TABLE orders_1 (
  CHECK (price > :price_limit)
) INHERITS (orders);
CREATE TABLE orders_2 (
  CHECK (price <= :price_limit)
) INHERITS (orders);

-- Копируем данные из основной таблицы в партиции
INSERT INTO orders_1 SELECT * FROM orders WHERE price > :price_limit;
INSERT INTO orders_2 SELECT * FROM orders WHERE price <= :price_limit;

-- Удаляем данные ТОЛЬКО из основной таблицы (если бы перекрытии было не полным, то с WHERE)
DELETE FROM ONLY orders;

-- Создаём правила для записи данных в партиции вместо основной таблицы
CREATE RULE orders_inserts_to_1_part AS 
  ON INSERT TO orders WHERE (price > :price_limit)
  DO INSTEAD INSERT INTO orders_1 VALUES (NEW.*);
CREATE RULE orders_inserts_to_2_part AS 
  ON INSERT TO orders WHERE (price <= :price_limit)
  DO INSTEAD INSERT INTO orders_2 VALUES (NEW.*);

COMMIT;
```

Проверяем как прошло разбиение
```bash
test_database=# SELECT * FROM orders_1;
 id |       title        | price
----+--------------------+-------
  2 | My little database |   500
  6 | WAL never lies     |   900
  8 | Dbiezdmin          |   501
(3 rows)

test_database=# SELECT * FROM orders_2;
 id |        title         | price
----+----------------------+-------
  1 | War and peace        |   100
  3 | Adventure psql time  |   300
  4 | Server gravity falls |   300
  5 | Log gossips          |   123
  7 | Me and my bash-pet   |   499
(5 rows)

test_database=# SELECT * FROM ONLY orders;
 id | title | price
----+-------+-------
(0 rows)

test_database=# SELECT * FROM orders;
 id |        title         | price
----+----------------------+-------
  2 | My little database   |   500
  6 | WAL never lies       |   900
  8 | Dbiezdmin            |   501
  1 | War and peace        |   100
  3 | Adventure psql time  |   300
  4 | Server gravity falls |   300
  5 | Log gossips          |   123
  7 | Me and my bash-pet   |   499
(8 rows)

```

### Шаг 2. Исключение ручного разбиения

* Можно во время создания таблицы было воспользоваться синтаксисом [PARTITION BY | PARTITION OF](https://postgrespro.com/docs/postgresql/11/sql-createtable)
* Можно взять готовую хранимую [процедуру](https://github.com/2gis/partition_magic), которая будет автоматически добавлять нужные таблицы. 


## Задача 4

Используя утилиту `pg_dump` создайте бекап БД `test_database`.

Как бы вы доработали бэкап-файл, чтобы добавить уникальность значения столбца `title` для таблиц `test_database`?
