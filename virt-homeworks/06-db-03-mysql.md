# 6.3. MySQL

Перед выполнением задания вы можете ознакомиться с 
[дополнительными материалами](https://github.com/netology-code/virt-homeworks/tree/master/additional/README.md).

## Задача 1

Используя docker поднимите инстанс MySQL (версию 8). Данные БД сохраните в volume.

Изучите [бэкап БД](https://github.com/netology-code/virt-homeworks/tree/master/06-db-03-mysql/test_data) и 
восстановитесь из него.

Перейдите в управляющую консоль `mysql` внутри контейнера.

Используя команду `\h` получите список управляющих команд.

Найдите команду для выдачи статуса БД и **приведите в ответе** из ее вывода версию сервера БД.

Подключитесь к восстановленной БД и получите список таблиц из этой БД.

**Приведите в ответе** количество записей с `price` > 300.

В следующих заданиях мы будем продолжать работу с данным контейнером.

**Ответ**

### Шаг 0. Подготовка окружения

Устанавливаем docker и docker-compose при необходимости (см. [6.2. SQL](https://github.com/Roma-EDU/devops-netology/blob/master/virt-homeworks/06-db-02-sql.md))

Пишем манифест docker-compose.yml для запуска контейнера с mysql версии 8:
```yml
version: '3.9'

networks:
  localnet:
    driver: bridge
    
volumes:
  mysql_volume:

services:
  mysql_service:
    container_name: mysql_container
    image: mysql:8
    command: --default-authentication-plugin=mysql_native_password
    environment:
      MYSQL_ROOT_PASSWORD: pwd4mysql
    volumes:
      - mysql_volume:/etc/mysql/
    restart: always
    networks:
      - localnet
```

Переходим в рабочую папку, разворачиваем контейнер
```bash
$ cd /vagrant/06-db-03-mysql
$ sudo docker-compose up
Creating network "06-db-03-mysql_localnet" with driver "bridge"
Creating volume "06-db-03-mysql_mysql_volume" with default driver
Pulling mysql_service (mysql:8)...
8: Pulling from library/mysql
6552179c3509: Pull complete
...
```

И копируем туда файлы бэкапа
```bash
$ sudo docker cp test_dump.sql mysql_container:/etc/mysql/test_dump.sql
```

### Шаг 1. Разворачиваем бэкап

Подключаемся к контейнеру и переходим в mysql с вводом пароля из MYSQL_ROOT_PASSWORD
```bash
$ sudo docker exec -ti mysql_container /bin/bash
$ mysql -uroot -p
Enter password:
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 8
Server version: 8.0.28 MySQL Community Server - GPL

Copyright (c) 2000, 2022, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.
```

Для того, чтобы развернуть бэкап, необходимо иметь соответствующую базу данных. Проверяем что её ещё нет (``test_db``), создаём и восстанавливаем из бэкапа
```bash
mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| sys                |
+--------------------+
4 rows in set (0.03 sec)

mysql> create database test_db;
Query OK, 1 row affected (0.01 sec)

mysql> use test_db;
Database changed
mysql> source test_dump.sql;
Query OK, 0 rows affected (0.00 sec)
...
```

### Шаг 2. Узнаём статус БД

С помощью команды ``\h`` (help) узнаём, что статус БД определяется командой ``status`` :). 
Версия отображается первой строкой Ver 8.0.28 for Linux on x86_64 (MySQL Community Server - GPL)
```bash
mysql> \h

For information about MySQL products and services, visit:
   http://www.mysql.com/
For developer information, including the MySQL Reference Manual, visit:
   http://dev.mysql.com/
To buy MySQL Enterprise support, training, or other products, visit:
   https://shop.mysql.com/

List of all MySQL commands:
Note that all text commands must be first on line and end with ';'
?         (\?) Synonym for `help'.
clear     (\c) Clear the current input statement.
connect   (\r) Reconnect to the server. Optional arguments are db and host.
delimiter (\d) Set statement delimiter.
edit      (\e) Edit command with $EDITOR.
ego       (\G) Send command to mysql server, display result vertically.
exit      (\q) Exit mysql. Same as quit.
go        (\g) Send command to mysql server.
help      (\h) Display this help.
nopager   (\n) Disable pager, print to stdout.
notee     (\t) Don't write into outfile.
pager     (\P) Set PAGER [to_pager]. Print the query results via PAGER.
print     (\p) Print current command.
prompt    (\R) Change your mysql prompt.
quit      (\q) Quit mysql.
rehash    (\#) Rebuild completion hash.
source    (\.) Execute an SQL script file. Takes a file name as an argument.
status    (\s) Get status information from the server.
system    (\!) Execute a system shell command.
tee       (\T) Set outfile [to_outfile]. Append everything into given outfile.
use       (\u) Use another database. Takes database name as argument.
charset   (\C) Switch to another charset. Might be needed for processing binlog with multi-byte charsets.
warnings  (\W) Show warnings after every statement.
nowarning (\w) Don't show warnings after every statement.
resetconnection(\x) Clean session context.
query_attributes Sets string parameters (name1 value1 name2 value2 ...) for the next query to pick up.

For server side help, type 'help contents'

mysql> status;
--------------
mysql  Ver 8.0.28 for Linux on x86_64 (MySQL Community Server - GPL)

Connection id:          8
Current database:       test_db
Current user:           root@localhost
SSL:                    Not in use
Current pager:          stdout
Using outfile:          ''
Using delimiter:        ;
Server version:         8.0.28 MySQL Community Server - GPL
Protocol version:       10
Connection:             Localhost via UNIX socket
Server characterset:    utf8mb4
Db     characterset:    utf8mb4
Client characterset:    latin1
Conn.  characterset:    latin1
UNIX socket:            /var/run/mysqld/mysqld.sock
Binary data as:         Hexadecimal
Uptime:                 2 hours 35 min 41 sec

Threads: 2  Questions: 40  Slow queries: 0  Opens: 142  Flush tables: 3  Open tables: 60  Queries per second avg: 0.004
--------------

```

### Шаг 3. Узнаём список таблиц и просматриваем их содержимое

Список таблиц узнаём командой `show tables;` (всего одна таблица orders). Количество записей, с ценой строго больше 300 - одна
```sql
mysql> show tables;
+-------------------+
| Tables_in_test_db |
+-------------------+
| orders            |
+-------------------+
1 row in set (0.01 sec)

mysql> SELECT * FROM orders;
+----+-----------------------+-------+
| id | title                 | price |
+----+-----------------------+-------+
|  1 | War and Peace         |   100 |
|  2 | My little pony        |   500 |
|  3 | Adventure mysql times |   300 |
|  4 | Server gravity falls  |   300 |
|  5 | Log gossips           |   123 |
+----+-----------------------+-------+
5 rows in set (0.00 sec)

mysql> SELECT COUNT(*) FROM orders WHERE price > 300;
+----------+
| COUNT(*) |
+----------+
|        1 |
+----------+
1 row in set (0.00 sec)
```


## Задача 2

Создайте пользователя test в БД c паролем test-pass, используя:
- плагин авторизации mysql_native_password
- срок истечения пароля - 180 дней 
- количество попыток авторизации - 3 
- максимальное количество запросов в час - 100
- аттрибуты пользователя:
    - Фамилия "Pretty"
    - Имя "James"

Предоставьте привелегии пользователю `test` на операции SELECT базы `test_db`.
    
Используя таблицу INFORMATION_SCHEMA.USER_ATTRIBUTES получите данные по пользователю `test` и 
**приведите в ответе к задаче**.

### Шаг 1. Создаём пользователя

Создаём пользователя `test` с необходимыми настройками (их порядок важен) и предоставляем ему права на все существующие таблицы базы test_db на SELECT

```sql
mysql> CREATE USER 'test'@'localhost' 
    -> IDENTIFIED WITH mysql_native_password BY 'test-pass' 
    -> WITH MAX_QUERIES_PER_HOUR 100 
    -> PASSWORD EXPIRE INTERVAL 180 DAY 
    -> FAILED_LOGIN_ATTEMPTS 3 
    -> ATTRIBUTE '{"fname": "James", "lname": "Pretty"}';
Query OK, 0 rows affected (0.05 sec)

mysql> GRANT SELECT ON test_db.* TO 'test'@'localhost';
Query OK, 0 rows affected, 1 warning (0.02 sec)

mysql> SELECT * FROM INFORMATION_SCHEMA.USER_ATTRIBUTES WHERE user = 'test';
+------+-----------+---------------------------------------+
| USER | HOST      | ATTRIBUTE                             |
+------+-----------+---------------------------------------+
| test | localhost | {"fname": "James", "lname": "Pretty"} |
+------+-----------+---------------------------------------+
1 row in set (0.00 sec)
```

## Задача 3

Установите профилирование `SET profiling = 1`.
Изучите вывод профилирования команд `SHOW PROFILES;`.

Исследуйте, какой `engine` используется в таблице БД `test_db` и **приведите в ответе**.

Измените `engine` и **приведите время выполнения и запрос на изменения из профайлера в ответе**:
- на `MyISAM`
- на `InnoDB`

**Ответ**

### Шаг 1. Включаем профилирование запросов и смотрим движки таблиц

Информация о движке хранится в `information_schema.TABLES`. Для таблицы `orders` используется движок по умолчанию `InnoDB`. 
В конце не забываем отключить профилирование

```sql
mysql> SET profiling = 1;
Query OK, 0 rows affected, 1 warning (0.00 sec)

mysql> SHOW PROFILES;
Empty set, 1 warning (0.00 sec)

mysql> SELECT table_name, engine FROM information_schema.TABLES WHERE table_schema = 'test_db';
+------------+--------+
| TABLE_NAME | ENGINE |
+------------+--------+
| orders     | InnoDB |
+------------+--------+
1 row in set (0.01 sec)

mysql> ALTER TABLE orders ENGINE = MyISAM;
Query OK, 5 rows affected (0.23 sec)
Records: 5  Duplicates: 0  Warnings: 0

mysql> ALTER TABLE orders ENGINE = InnoDB;
Query OK, 5 rows affected (0.15 sec)
Records: 5  Duplicates: 0  Warnings: 0

mysql> SHOW PROFILES;
+----------+------------+--------------------------------------------------------------------------+
| Query_ID | Duration   | Query                                                                    |
+----------+------------+--------------------------------------------------------------------------+
|        1 | 0.00239400 | SELECT table_name, engine FROM information_schema.TABLES WHERE table_schema = 'test_db' |
|        2 | 0.00404100 | SHOW ENGINES                                                             |
|        3 | 0.00169450 | SELECT * FROM orders                                                     |
|        4 | 0.02109325 | SELECT * FROM information_schema.TABLES WHERE table_name = 'orders'      |
|        5 | 0.00305400 | SELECT * FROM information_schema.TABLES WHERE table_schema = 'test_db'   |
|        6 | 0.00072450 | SHOW WARNINGS                                                            |
|        7 | 0.22506275 | ALTER TABLE orders ENGINE = MyISAM                                       |
|        8 | 0.15286250 | ALTER TABLE orders ENGINE = InnoDB                                       |
+----------+------------+--------------------------------------------------------------------------+
8 rows in set, 1 warning (0.00 sec)

mysql> SET profiling = 0;
Query OK, 0 rows affected, 1 warning (0.00 sec)

```


## Задача 4 

Изучите файл `my.cnf` в директории /etc/mysql.

Измените его согласно ТЗ (движок InnoDB):
- Скорость IO важнее сохранности данных
- Нужна компрессия таблиц для экономии места на диске
- Размер буффера с незакомиченными транзакциями 1 Мб
- Буффер кеширования 30% от ОЗУ
- Размер файла логов операций 100 Мб

Приведите в ответе измененный файл `my.cnf`.

### Шаг 0*. Подготавливаем окружение

С помощью `cat /etc/*-release` узнаём, что образ основан на debian, поэтому чуть-чуть другой синтаксис. Обновляем репозитории и устанавливаем редактор `nano`
```bash
mysql> exit
Bye
$ cat /etc/*-release
PRETTY_NAME="Debian GNU/Linux 10 (buster)"
NAME="Debian GNU/Linux"
VERSION_ID="10"
VERSION="10 (buster)"
VERSION_CODENAME=buster
ID=debian
HOME_URL="https://www.debian.org/"
SUPPORT_URL="https://www.debian.org/support"
BUG_REPORT_URL="https://bugs.debian.org/"

$ apt update
...
$ apt install nano
Reading package lists... Done
Building dependency tree
Reading state information... Done
Suggested packages:
  spell
The following NEW packages will be installed:
  nano
0 upgraded, 1 newly installed, 0 to remove and 0 not upgraded.
Need to get 544 kB of archives.
After this operation, 2269 kB of additional disk space will be used.
Get:1 http://deb.debian.org/debian buster/main amd64 nano amd64 3.2-3 [544 kB]
Fetched 544 kB in 0s (2678 kB/s)
debconf: delaying package configuration, since apt-utils is not installed
Selecting previously unselected package nano.
(Reading database ... 9323 files and directories currently installed.)
Preparing to unpack .../archives/nano_3.2-3_amd64.deb ...
```

### Шаг 1. Редактируем конфигурационный файл

Добавляем раздел InnoDB согласно требованиям в файл /etc/mysql/my.cnf
```bash
$ nano my.cnf
$ cat my.cnf
# Copyright (c) 2017, Oracle and/or its affiliates. All rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA

#
# The MySQL  Server configuration file.
#
# For explanations see
# http://dev.mysql.com/doc/mysql/en/server-system-variables.html

[mysqld]
pid-file        = /var/run/mysqld/mysqld.pid
socket          = /var/run/mysqld/mysqld.sock
datadir         = /var/lib/mysql
secure-file-priv= NULL

## InnoDB
innodb_flush_log_at_trx_commit = 2
innodb_file_per_table = 1
innodb_log_buffer_size = 1M
innodb_buffer_pool_size = 600M
innodb_log_file_size = 100M

# Custom config should go here
!includedir /etc/mysql/conf.d/
```

### Шаг 2. Рестартуем сервис, чтобы изменения вступили в силу

Выходим из контейнера (несколько команд `exit`) и просим докер рестартовать
```bash
$ sudo docker-compose restart
Restarting mysql_container ... done
```

### Шаг 3*. Выключаем всё :)

```bash
$ sudo docker-compose down
Stopping mysql_container ... done
Removing mysql_container ... done
Removing network 06-db-03-mysql_localnet
$ exit
logout
Connection to 127.0.0.1 closed.

>vagrant halt
==> default: Attempting graceful shutdown of VM...
```
