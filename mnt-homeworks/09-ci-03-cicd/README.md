# 9.3. CI\CD

## Подготовка к выполнению

1. Создаём 2 VM в yandex cloud со следующими параметрами: 2CPU 4RAM Centos7(остальное по минимальным требованиям)
   * Подробное описание шагов подготовки (инициализация Yandex.Cloud, создание виртуалок с помощью Terraform, и т.п.) см. в предыдущем ДЗ [08-ansible-02-playbook](https://github.com/Roma-EDU/devops-netology/tree/master/mnt-homeworks/08-ansible-02-playbook)
2. Прописываем в [inventory](./infrastructure/inventory/cicd/hosts.yml) [playbook'a](./infrastructure/site.yml) созданные хосты
   * Копируем IP серверов в hosts.yml, в качестве пользователя ansible_user прописываем `centos`
3. Добавляем в [files](./infrastructure/files/) файл со своим публичным ключом (id_rsa.pub). Если ключ называется иначе - найдите таску в плейбуке, которая использует id_rsa.pub имя и исправьте на своё
   * Переходим в папку и копируем в неё наш публичный ключ
     ```bash
     $ cd /vagrant/09-ci-03-cicd/infrastructure/files/
     $ cp ~/.ssh/id_rsa.pub id_rsa.pub
     ```
4. Запускаем playbook, ожидаем успешного завершения
   * Переходим на уровень выше `cd ..` в папку с `site.yml`
   * Запуск установки sonar `ansible-playbook -i inventory/cicd site.yml --diff` и достаточно долгое ожидание установки
   * Потом это дело падает, видимо из-за замены пользователя при настройке sonar'а
   * Продолжаем установку nexus с неуспешного шага `ansible-playbook -i inventory/cicd site.yml --start-at-task='Create Nexus group' --diff`
5. Проверяем готовность Sonarqube через [браузер](http://localhost:9000)
   * Переходим в SonarQube с помощью внешнего IP, указанного в `hosts.yml` по 9000 порту
6. Заходим под admin\admin, меняем пароль на свой
   * Зашёл, пароль сменил
7. Проверяем готовность Nexus через [браузер](http://localhost:8081)
   * Аналогично с помощью внешнего IP из hosts.yml заходим в Nexus по 8081 порту
8. Подключаемся под admin\admin123, меняем пароль, сохраняем анонимный доступ
   * Зашёл, поменял пароль в правом верхнем углу

## Знакомство с SonarQube

### Основная часть

1. Создаём новый проект, название произвольное
   * Создал проект с типом `<Manually>`, название `netology` (да, тоже не стал выдумывать ;))
2. Скачиваем пакет sonar-scanner, который нам предлагает скачать сам sonarqube
   * После создания было предложено перейти по [ссылке](https://docs.sonarqube.org/latest/analysis/scan/sonarscanner/) и скачать там сканер для установки на машину, где расположен код (выбрал zip-архив для Linux x64) 
3. Делаем так, чтобы binary был доступен через вызов в shell (или меняем переменную PATH или любой другой удобный вам способ)
   * Распаковал архив в рабочую папку
   * Перешёл в папку с bin, добавил её в перемунную PATH: 
   ```bash
   $ cd /vagrant/09-ci-03-cicd//sonar/bin
   $ export PATH=$(pwd):$PATH
   ```
4. Проверяем `sonar-scanner --version`
   * Переходим в папку с кодом, проверяем версию сканера
   ```bash
   $ cd ../../example/
   $ sonar-scanner --version
   INFO: Scanner configuration file: /vagrant/09-ci-03-cicd/sonar/conf/sonar-scanner.properties
   INFO: Project root configuration file: NONE
   INFO: SonarScanner 4.7.0.2747
   INFO: Java 11.0.14.1 Eclipse Adoptium (64-bit)
   INFO: Linux 5.4.0-105-generic amd64
   ```
5. Запускаем анализатор против кода из директории [example](./example) с дополнительным ключом `-Dsonar.coverage.exclusions=fail.py`
   * Запускаем анализатор (опции запуска были получены при настройке проекта для языка из группы Other + дописан ключ исключения тестов)
   ```bash
   $ sonar-scanner \
   >   -Dsonar.projectKey=netology \
   >   -Dsonar.sources=. \
   >   -Dsonar.host.url=http://51.250.2.231:9000 \
   >   -Dsonar.login=3bc764a77a568d22819437a2e5ab9386a2206733 \
   >   -Dsonar.coverage.exclusions=fail.py
   ```
6. Смотрим результат в интерфейсе
   * Посмотрел
7. Исправляем ошибки, которые он выявил(включая warnings)
   * Исправил 2 бага и 1 code smell
8. Запускаем анализатор повторно - проверяем, что QG пройдены успешно
   * Запустил
9. Делаем скриншот успешного прохождения анализа, прикладываем к решению ДЗ
   ![image](https://user-images.githubusercontent.com/77544263/172010066-00233204-5730-41f0-8058-4c46ca450967.png)


## Знакомство с Nexus

### Основная часть

1. В репозиторий `maven-public` загружаем артефакт с GAV параметрами:
   1. groupId: netology
   2. artifactId: java
   3. version: 8_282
   4. classifier: distrib
   5. type: tar.gz
2. В него же загружаем такой же артефакт, но с version: 8_102
3. Проверяем, что все файлы загрузились успешно
4. В ответе присылаем файл `maven-metadata.xml` для этого артефекта

**Ответ**
Через кнопку Upload (появляется слева после логина) залил в репозиторий `maven-release` (maven-public недоступен, но артефакт сам туда попадает из release) файлы. Файл [netology/java/maven-metadata.xml](./maven-metadata.xml) приложил
![image](https://user-images.githubusercontent.com/77544263/172013870-7ff1abd5-f352-4d27-93e5-8e9c364db79f.png)


### Знакомство с Maven

### Подготовка к выполнению

1. Скачиваем дистрибутив с [maven](https://maven.apache.org/download.cgi)
2. Разархивируем, делаем так, чтобы binary был доступен через вызов в shell (или меняем переменную PATH или любой другой удобный вам способ)
3. Удаляем из `apache-maven-<version>/conf/settings.xml` упоминание о правиле, отвергающем http соединение( раздел mirrors->id: my-repository-http-unblocker)
4. Проверяем `mvn --version`
5. Забираем директорию [mvn](./mvn) с pom

### Основная часть

1. Меняем в `pom.xml` блок с зависимостями под наш артефакт из первого пункта задания для Nexus (java с версией 8_282)
2. Запускаем команду `mvn package` в директории с `pom.xml`, ожидаем успешного окончания
3. Проверяем директорию `~/.m2/repository/`, находим наш артефакт
4. В ответе присылаем исправленный файл `pom.xml`
