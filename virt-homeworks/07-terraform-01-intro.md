# 7.1. Инфраструктура как код

## Задача 1. Выбор инструментов. 
 
### Легенда
 
Через час совещание на котором менеджер расскажет о новом проекте. Начать работу над которым надо 
будет уже сегодня. 
На данный момент известно, что это будет сервис, который ваша компания будет предоставлять внешним заказчикам.
Первое время, скорее всего, будет один внешний клиент, со временем внешних клиентов станет больше.

Так же по разговорам в компании есть вероятность, что техническое задание еще не четкое, что приведет к большому
количеству небольших релизов, тестирований интеграций, откатов, доработок, то есть скучно не будет.  
   
Вам, как девопс инженеру, будет необходимо принять решение об инструментах для организации инфраструктуры.
На данный момент в вашей компании уже используются следующие инструменты: 
- остатки Сloud Formation, 
- некоторые образы сделаны при помощи Packer,
- год назад начали активно использовать Terraform, 
- разработчики привыкли использовать Docker, 
- уже есть большая база Kubernetes конфигураций, 
- для автоматизации процессов используется Teamcity, 
- также есть совсем немного Ansible скриптов, 
- и ряд bash скриптов для упрощения рутинных задач.  

Для этого в рамках совещания надо будет выяснить подробности о проекте, что бы в итоге определиться с инструментами:

1. Какой тип инфраструктуры будем использовать для этого проекта: изменяемый или не изменяемый?
1. Будет ли центральный сервер для управления инфраструктурой?
1. Будут ли агенты на серверах?
1. Будут ли использованы средства для управления конфигурацией или инициализации ресурсов? 
 
В связи с тем, что проект стартует уже сегодня, в рамках совещания надо будет определиться со всеми этими вопросами.

### В результате задачи необходимо

1. Ответить на четыре вопроса представленных в разделе "Легенда". 
1. Какие инструменты из уже используемых вы хотели бы использовать для нового проекта? 
1. Хотите ли рассмотреть возможность внедрения новых инструментов для этого проекта? 

Если для ответа на эти вопросы недостаточно информации, то напишите какие моменты уточните на совещании.

**Ответ**

### Шаг 1. Вопросы раздела "Легенда"

1. Какой тип инфраструктуры будем использовать для этого проекта: изменяемый или не изменяемый?
   * С одной стороны кажется, что на первых шагах с наличием большой неопределённости и высокой скоростью правок имеет смысл воспользоваться изменяемой инфраструктурой с плавным переходом к неизменяемой. С другой стороны, нет ничего более постоянного, чем временное, поэтому не будем привыкать к "плохому", и сразу воспользуемся неизменяемым типом. Это привнесёт не такие уж большие задержки, зато команда повысит компетенции и к моменту роста количества клиентов всё будет готово.
2. Будет ли центральный сервер для управления инфраструктурой?
   * Поскольку среди нашего стека нет инструментов, которым требуется центральный сервер, вводить мы его не будем
3. Будут ли агенты на серверах?
   * Нет центрального сервера - нет агентов
4. Будут ли использованы средства для управления конфигурацией или инициализации ресурсов? 
   * Будут средства для инициализации ресурсов - Terraform

### Шаг 2. Инструменты в проекте

1. Packer - для создания образов виртуальных машин
2. Terraform - создание ресурсов из подготовленного образа
3. Docker - разработчики привыкли, почему бы и нет)
4. Kubernetes - как средство оркестрации, к тому же у нас уже есть большая база
5. Teamcity - CI/CD инструмент
6. Другое по необходимости

### Шаг 3. Внедрение новых инструментов

Пожалуй стоит добавить средства мониторинга для оперативного наблюдения за состоянием серверов (prometeus, grafana) в связке с отправкой уведомлений (мессенжер, почта, смски)


## Задача 2. Установка терраформ. 

Официальный сайт: https://www.terraform.io/

Установите терраформ при помощи менеджера пакетов используемого в вашей операционной системе.
В виде результата этой задачи приложите вывод команды `terraform --version`.

**Ответ**

### Шаг 1. Установка terraform

Включаем впн :(
Воспользуемся официальными [рекомендациями](https://learn.hashicorp.com/tutorials/terraform/install-cli?in=terraform/aws-get-started#install-terraform) разработчика (см. вкладку Linux)

```bash
$ sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl
Hit:1 http://archive.ubuntu.com/ubuntu focal InRelease
...
$ curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
OK
$ sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
Hit:1 http://archive.ubuntu.com/ubuntu focal InRelease
...
Reading package lists... Done
$ sudo apt-get update && sudo apt-get install terraform
Hit:1 http://archive.ubuntu.com/ubuntu focal InRelease
...
Unpacking terraform (1.1.7) ...
Setting up terraform (1.1.7) ...
```

### Шаг 2. Проверяем версию

```bash
$ terraform --version
Terraform v1.1.7
on linux_amd64
```


## Задача 3. Поддержка легаси кода. 

В какой-то момент вы обновили терраформ до новой версии, например с 0.12 до 0.13. 
А код одного из проектов настолько устарел, что не может работать с версией 0.13. 
В связи с этим необходимо сделать так, чтобы вы могли одновременно использовать последнюю версию терраформа установленную при помощи
штатного менеджера пакетов и устаревшую версию 0.12. 

В виде результата этой задачи приложите вывод `--version` двух версий терраформа доступных на вашем компьютере 
или виртуальной машине.

**Ответ**

### Шаг 0. Подготовка

1. Находим на [сайте](https://releases.hashicorp.com/terraform/) нужную версию терраформа и подходящую версию, например для Ubuntu 20.04 на Intel выберем 0.15.5: https://releases.hashicorp.com/terraform/0.15.5/terraform_0.15.5_linux_amd64.zip
2. Устанавливаем доппакеты для распаковки архива `sudo apt-get install unzip`
3. Если будет проблема с зависанием на этапе `Processing triggers for man-db (2.9.1-1)`, то можно пересоздать индекс (тоже занимает прилично времени, но зато потом быстрее будет [подробности](https://thelinuxuser.com/fix-processing-triggers-for-man-db/))
   ```bash
   $ sudo rm -rf /var/cache/man/*
   $ sudo mandb -c
   ```
   
### Шаг 1. Установка альтернативной версии терраформ

> **Альтернатива**: Вместо всех шагов ниже можно взять готовые решения, позволяющие устанавливать несколько версий терраформ, например [Terraform Switcher](https://github.com/warrensbox/terraform-switcher#terraform-switcher), [tfenv](https://github.com/tfutils/tfenv#tfenv) и другие

1. Создаём папку с альтернативной версией /opt/terraform/015/
2. Скачиваем и распаковываем в неё соответствующий архив
3. Создаём символическую ссылку для удобного вызова (пусть будет `terraform015`)
4. Выдаём права на исполнение

```bash
$ sudo mkdir -p /opt/terraform/015/
$ cd /opt/terraform/015/
$ sudo wget https://releases.hashicorp.com/terraform/0.15.5/terraform_0.15.5_linux_amd64.zip
--2022-03-10 20:35:50--  https://releases.hashicorp.com/terraform/0.15.5/terraform_0.15.5_linux_amd64.zip
...
2022-03-10 20:36:02 (2.72 MB/s) - ‘terraform_0.15.5_linux_amd64.zip’ saved [33043317/33043317]

$ sudo unzip terraform_0.15.5_linux_amd64.zip
Archive:  terraform_0.15.5_linux_amd64.zip
  inflating: terraform
$ sudo rm terraform_0.15.5_linux_amd64.zip
$ sudo ln -s /opt/terraform/015/terraform /usr/bin/terraform015
$ sudo chmod ugo+x /usr/bin/terraform015
```



### Шаг 2. Проверяем версию

```bash
$ terraform015 --version
Terraform v0.15.5
on linux_amd64

Your version of Terraform is out of date! The latest version
is 1.1.7. You can update by downloading from https://www.terraform.io/downloads.html
$ terraform --version
Terraform v1.1.7
on linux_amd64
```