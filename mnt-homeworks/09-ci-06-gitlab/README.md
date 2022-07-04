# 9.6. Gitlab

## Подготовка к выполнению

>1. Необходимо [подготовить gitlab к работе по инструкции](https://cloud.yandex.ru/docs/tutorials/infrastructure-management/gitlab-containers)
>2. Создайте свой новый проект
>3. Создайте новый репозиторий в gitlab, наполните его [файлами](./repository)
>4. Проект должен быть публичным, остальные настройки по желанию

**Ответ**: надо очень внимательно пройти по всем шагам, описанным в инструкции, в том числе и по ссылкам

## Основная часть

### DevOps

>В репозитории содержится код проекта на python. Проект - RESTful API сервис. Ваша задача автоматизировать сборку образа с выполнением python-скрипта:
>1. Образ собирается на основе [centos:7](https://hub.docker.com/_/centos?tab=tags&page=1&ordering=last_updated)
>2. Python версии не ниже 3.7
>3. Установлены зависимости: `flask` `flask-jsonpify` `flask-restful`
>4. Создана директория `/python_api`
>5. Скрипт из репозитория размещён в /python_api
>6. Точка вызова: запуск скрипта
>7. Если сборка происходит на ветке `master`: должен подняться pod kubernetes на основе образа `python-api`, иначе этот шаг нужно пропустить

**Ответ**:
* Создание образа (пункты 1-6) - в [Dockerfile](./repository/Dockerfile)
* Сборка по ветке main - за счёт ключевого слова `only` в deploy [gitlab-ci.yml](./repository/gitlab-ci.yml) (название должно начинаться с точки `.gitlab-ci.yml`, но тогда github не показыывает этот файл )

### Product Owner

>Вашему проекту нужна бизнесовая доработка: необходимо поменять JSON ответа на вызов метода GET `/rest/api/get_info`, необходимо создать Issue в котором указать:
>1. Какой метод необходимо исправить
>2. Текст с `{ "message": "Already started" }` на `{ "message": "Running"}`
>3. Issue поставить label: feature

**Ответ**: завёл новый Issue, проставил label

### Developer

>Вам пришел новый Issue на доработку, вам необходимо:
>1. Создать отдельную ветку, связанную с этим issue
>2. Внести изменения по тексту из задания
>3. Подготовить Merge Request, влить необходимые изменения в `master`, проверить, что сборка прошла успешно

**Ответ**: создал Draft Merge Request и ветку, поправил код, проставил автомёрж при успешном билде - всё собралось, Issue закрылся

### Tester

>Разработчики выполнили новый Issue, необходимо проверить валидность изменений:
>1. Поднять докер-контейнер с образом `python-api:latest` и проверить возврат метода на корректность
>2. Закрыть Issue с комментарием об успешности прохождения, указав желаемый результат и фактически достигнутый

**Ответ**:
* Авторизовался в [YC](https://cloud.yandex.ru/docs/container-registry/operations/authentication#sa)
  ```bash
  $ yc iam key create --service-account-name kubernetes-service-account -o key.json
  id: ajennvh3ebtotfd08qmm
  service_account_id: aje7vjrhmcl4loja1elc
  created_at: "2022-07-04T00:18:42.941985009Z"
  key_algorithm: RSA_2048

  $ cat key.json | docker login --username json_key --password-stdin cr.yandex
  WARNING! Your password will be stored unencrypted in /home/vagrant/.docker/config.json.
  Configure a credential helper to remove this warning. See
  https://docs.docker.com/engine/reference/commandline/login/#credentials-store
  
  Login Succeeded
  ```
* Скачал и запустил контейнер
  ```bash
  $ docker pull cr.yandex/crpukibr0cdk8jg9rk37/hello:gitlab-e5ae2ffa
  ...
  Status: Downloaded newer image for cr.yandex/crpukibr0cdk8jg9rk37/hello:gitlab-e5ae2ffa
  cr.yandex/crpukibr0cdk8jg9rk37/hello:gitlab-e5ae2ffa
  $ docker run -d fae15cda1878
  cc64d2ddfda028732a0e7f23c9d78ce84bc8b3e8bf5ac8173596dae662e14423
  ```
* Подключился к контейнеру и проверил, что всё работает
  ```bash
  $ docker exec -it cc64d2ddfda0 /bin/bash
  $ curl  http://172.17.0.2:5290/get_info
  {"version": 3, "method": "GET", "message": "Running"}
  ```

## Итог

>После успешного прохождения всех ролей - отправьте ссылку на ваш проект в гитлаб, как решение домашнего задания

**Ответ**: ссылка на [gitlab](https://roma4edu.gitlab.yandexcloud.net/roma/gitlab-test) - естественно перестанет действовать после выключения YC 

### :bangbang: Не забудьте оставить GitLab рабочим после выполнения задания и погасить все ресурсы в Yandex.Cloud сразу после получения зачета по домашнему заданию.

## ~Необязательная часть~

>Автомазируйте работу тестировщика, пусть у вас будет отдельный конвейер, который автоматически поднимает контейнер и выполняет проверку, например, при помощи curl. На основе вывода - будет приниматься решение об успешности прохождения тестирования


