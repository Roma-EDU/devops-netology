
# 5.3. Введение. Экосистема. Архитектура. Жизненный цикл Docker контейнера

## Задача 1

Сценарий выполения задачи:

- создайте свой репозиторий на https://hub.docker.com;
- выберете любой образ, который содержит веб-сервер Nginx;
- создайте свой fork образа;
- реализуйте функциональность:
запуск веб-сервера в фоне с индекс-страницей, содержащей HTML-код ниже:
```
<html>
<head>
Hey, Netology
</head>
<body>
<h1>I’m DevOps Engineer!</h1>
</body>
</html>
```
Опубликуйте созданный форк в своем репозитории и предоставьте ответ в виде ссылки на https://hub.docker.com/username_repo.

**Ответ:** cсылка на docker-образ https://hub.docker.com/r/roma4edu/netology_nginx

Подробности:

1. Создаём Vagrantfile, чтобы запускать всё это под Linux (хост-машина на Windows)
    ```ruby
    Vagrant.configure("2") do |config|
      config.vm.box = "bento/ubuntu-20.04"
      config.vm.network "forwarded_port", guest: 443, host: 4443
    
      config.vm.provider "virtualbox" do |vb|
        vb.memory = "1024"
  	  vb.cpus = "2"
  	  vb.name = "ubuntu_docker"
      end
    
      # install latest docker
      config.vm.provision "docker" do |d|
          d.run "hello-world"
      end
      
    end
    ```
2. После подключения к запущенной виртуальной машине (``vagrant up``, ``vagrant ssh``) создаём чистую директорию для работы с образом docker и переходим в неё
3. С помощью nano создаём файл index.html, содержащий требуемый HTML
4. С помощью nano создаём файл Dockerfile со следующим содержимым:
    ```ruby
    FROM nginx:stable
    COPY . /usr/share/nginx/html
    ```
    Т.е. модифицируем существующий официально поддерживаемого образ [Nginx](https://hub.docker.com/_/nginx) (стабильной версии :stable), поместив всё содержимое текущей директории (по сути только файлик index.html) в директорию /usr/share/nginx/html, которой пользутеся nginx
5. Ставим образ на сборку командой ``docker build -t roma4edu/netology_nginx:0.1 .`` (обязательна точка в конце = текущая директория) и ждём некоторое время (минут 10, в какой-то момент даже казалось, что всё зависло)
    ```bash
    $ docker build -t roma4edu/netology_nginx:0.1 .
    Sending build context to Docker daemon  3.072kB
    Step 1/2 : FROM nginx:stable
    stable: Pulling from library/nginx
    5eb5b503b376: Pull complete
    cdfeb356c029: Pull complete
    d86da7454448: Pull complete
    7976249980ef: Pull complete
    8f66aa6726b2: Pull complete
    c004cabebe76: Pull complete
    Digest: sha256:02923d65cde08a49380ab3f3dd2f8f90aa51fa2bd358bd85f89345848f6e6623
    Status: Downloaded newer image for nginx:stable
     ---> d6c9558ba445
    Step 2/2 : COPY . /usr/share/nginx/html
     ---> 45bd899ca601
    Successfully built 45bd899ca601
    Successfully tagged roma4edu/netology_nginx:0.1
    ```
6. Запускаем образ локально с проброской портов и проверяем, что всё работает как надо
    ```bash
    $ docker run -d -p 80:80 roma4edu/netology_nginx:0.1
    2c926f701de2b321d6af9e4b3b408694d808a78706b15eb9f314d37abb11b2b3
    $ curl localhost:80
    <html>
    <head>
    Hey, Netology
    </head>
    <body>
    <h1>I’m DevOps Engineer!</h1>
    </body>
    </html>
    ```
7. Останавливаем все образы
    ```bash
    $ docker stop $(docker ps -a -q)
    2c926f701de2
    59b8c21d9a75
    ```
8. Логинимся и заливаем образ в свой репозиторий на https://hub.docker.com
    ```bash
    $ docker login -u roma4edu
    Password:
    Login Succeeded
    $ docker push roma4edu/netology_nginx:0.1
    The push refers to repository [docker.io/roma4edu/netology_nginx]
    158ecd15d543: Pushed
    b1073b41766d: Mounted from library/nginx
    8fa2ccbce0c2: Mounted from library/nginx
    dc78c3d0e917: Mounted from library/nginx
    a64a30dea1c4: Mounted from library/nginx
    f7d96e665ae1: Mounted from library/nginx
    7d0ebbe3f5d2: Mounted from library/nginx
    0.1: digest: sha256:9a7af8aec731cc77863b4a19c81394087ec76413038ab95fc2e1661f4f4dc3ab size: 1777
    ```

## Задача 2

Посмотрите на сценарий ниже и ответьте на вопрос:
"Подходит ли в этом сценарии использование Docker контейнеров или лучше подойдет виртуальная машина, физическая машина? Может быть возможны разные варианты?"

Детально опишите и обоснуйте свой выбор.

--

Сценарий:

- Высоконагруженное монолитное java веб-приложение;
- Nodejs веб-приложение;
- Мобильное приложение c версиями для Android и iOS;
- Шина данных на базе Apache Kafka;
- Elasticsearch кластер для реализации логирования продуктивного веб-приложения - три ноды elasticsearch, два logstash и две ноды kibana;
- Мониторинг-стек на базе Prometheus и Grafana;
- MongoDB, как основное хранилище данных для java-приложения;
- Gitlab сервер для реализации CI/CD процессов и приватный (закрытый) Docker Registry.

## Задача 3

- Запустите первый контейнер из образа ***centos*** c любым тэгом в фоновом режиме, подключив папку ```/data``` из текущей рабочей директории на хостовой машине в ```/data``` контейнера;
- Запустите второй контейнер из образа ***debian*** в фоновом режиме, подключив папку ```/data``` из текущей рабочей директории на хостовой машине в ```/data``` контейнера;
- Подключитесь к первому контейнеру с помощью ```docker exec``` и создайте текстовый файл любого содержания в ```/data```;
- Добавьте еще один файл в папку ```/data``` на хостовой машине;
- Подключитесь во второй контейнер и отобразите листинг и содержание файлов в ```/data``` контейнера.

## Задача 4 (*)

Воспроизвести практическую часть лекции самостоятельно.

Соберите Docker образ с Ansible, загрузите на Docker Hub и пришлите ссылку вместе с остальными ответами к задачам.
