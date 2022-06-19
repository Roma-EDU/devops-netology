# 9.4. Jenkins

## Подготовка к выполнению

>1. Создать 2 VM: для jenkins-master и jenkins-agent.
>2. Установить jenkins при помощи playbook'a.
>3. Запустить и проверить работоспособность.
>4. Сделать первоначальную настройку.

### Ответ:

1. При помощи terraform, как в [08-ansible-02-playbook](../08-ansible-02-playbook) поднимаем два инстанса, получаем их IP
2. Подставляем IP в `hosts.yml`, в качестве пользователя указываем `centos`
3. Накатываем Jenkins и ряд вспомогательных инструментов с помощью ansible `ansible-playbook -i inventory/cicd site.yml`
4. Переходим в браузере на IP-мастера по порту `8080`, открывается форма настройки Jenkins
5. Как указано на форме, получаем пароль и вставляем его
   ```bash
   $ ssh centos@51.250.64.143
   [centos@jenkins-master-01 ~]$ sudo cat /var/lib/jenkins/secrets/initialAdminPassword
   ```
6. Устанавливаем рекомендуемые плагины
7. Настраиваем первого пользователя
8. Соглашаемся с предложенным URL для обращения к Jenkins
9. Настраиваем первого агента/ноды
   * Name - произвольное, пусть будет `agent-01`
   * Number of executors - по количеству CPU, у нас два ядра, поэтому 2
   * Корень удаленной ФС - это настраивалось в playbook, см jenkins_agent_dir `/opt/jenkins_agent/`
   * Метки - для классификаций  агентов, у нас 1, поэтому пропустим (там можно задавать любые теги через пробел)
   * Использование - Use this node as much as possible
   * Способ запуска - с помощью команды запуска
     `ssh 51.250.95.183 java -jar /opt/jenkins_agent/agent.jar`
   * Доступность - определяет доступность агента, но не выключает его виртуалку; может быть удобно при выполнении ночью каких-то действий, но нам пока не надо 
   * И сохраняем изменения. Затем можно зайти в агента, посмотреть логи, что он успешно подключился
10. Добавляем credentials:
    * Dashboard -> Настроить Jenkins -> Manage credentials -> Jenkins -> Global credentials -> слева кнопка Add credentials
    * Kind - SSH Username with private key
    * Scope - Global (...)
    * Username - пушить мы не будем, только скачивать, пусть будет имя `vagrant_git`
    * Private key - вводим сам ключ (стянув его `cat ~/.ssh/id_rsa`)
    * Passphrase - тоже вводим, если есть

## Основная часть

>1. Сделать Freestyle Job, который будет запускать `molecule test` из любого вашего репозитория с ролью.
>2. Сделать Declarative Pipeline Job, который будет запускать `molecule test` из любого вашего репозитория с ролью.
>3. Перенести Declarative Pipeline в репозиторий в файл `Jenkinsfile`.
>4. Создать Multibranch Pipeline на запуск `Jenkinsfile` из репозитория.
>5. Создать Scripted Pipeline, наполнить его скриптом из [pipeline](./pipeline).
>6. Внести необходимые изменения, чтобы Pipeline запускал `ansible-playbook` без флагов `--check --diff`, если не установлен параметр при запуске джобы (prod_run = True), по умолчанию параметр имеет значение False и запускает прогон с флагами `--check --diff`.
>7. Проверить работоспособность, исправить ошибки, исправленный Pipeline вложить в репозиторий в файл `ScriptedJenkinsfile`.
>8. Отправить ссылку на репозиторий с ролью и Declarative Pipeline и Scripted Pipeline.

### 1. Freestyle Job:

1. Название `vector-role` (так в момент выполнения на агенте будет создана папочка с таким же именем, а иначе при тесте не будет найдена роль)
2. Управление исходным кодом - Git
3. Repository URL - мой с ролью для vector: `git@github.com:Roma-EDU/vector-role.git`
4. Credentials - из выпадашки выбрал `vagrant_git`
5. Branches - оставил master по умолчанию
6. Проставил флажки `Опрашивать SCM об изменениях`, `Delete workspace before build starts` и `Add timestamps to the Console Output`
7. Сборка - один шаг с выполнением shell команды
```bash
pip3 uninstall "ansible-base"
pip3 install --user "cryptography==36.0.0" "ansible-core" "ansible-lint" "yamllint"
pip3 install --user "molecule==3.4.0" "molecule_docker" 
ansible-galaxy collection install community.docker
molecule --version
molecule test
```
Оказалось на агенте много чего нехватало или устарело, поэтому пришлось обновлять прямо на ходу: заменил старый ansible на новый, установил старую криптографию для Python 3.6 (была ошибка, что криптография устарела), добавил линтеров и обновил модуль, отвечающий за подключение к докеру (команда не поддерживалась)


### 2. Declarative & Multibranch Pipeline Job

1. Окружение уже настроено корректно, поэтому скрипт уже нормальный, каким и должен был бы быть в первом шаге. Скрипт такой
```groovy
pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                dir('vector-role') {
                    git credentialsId: 'c06a7f9a-4ea8-4a9b-b19b-5b4fef5c5a33', url: 'git@github.com:Roma-EDU/vector-role.git'
                }
            }
        }
        stage('Molecule') {
            steps {
                dir('vector-role') {
                    sh 'molecule --version'
                    sh 'molecule test'
                }
            }
        }
    }
}
```

2. Перенёс его же в [Jenkinsfile](https://github.com/Roma-EDU/vector-role/blob/1.2.1/Jenkinsfile) для vector-role
3. Создал Multibranch pipeline для запуска этого файла
   * Branch Sources: добавил один репозиторий git@github.com:Roma-EDU/vector-role.git с кредами `vagrant_git`
   * Build Configuration: by Jenkinsfile, путь к файлу `Jenkinsfile` (файл лежит в корне репозитория и называется Jenkinsfile)


### Scripted Pipeline

Создал Pipeline Job, указал, что это параметризованная сборка с Boolean параметром `prod_run`

В собираемом репозитории с ролью протухли кастомные указанные в requirements.yml креды, поэтому пришлось изворачиваться
Что пытался (и как по идее должно было бы работать)
```groovy
node("linux"){
    stage("Git checkout"){
        git credentialsId: 'c06a7f9a-4ea8-4a9b-b19b-5b4fef5c5a33', url: 'git@github.com:aragastmatb/example-playbook.git'
    }
    stage("Install dependencies"){
        sh 'ansible-vault decrypt --vault-password-file vault_pass secret'
        sh 'ansible-galaxy install -r requirements.yml -p roles'
    }
    stage("Run playbook"){
        if (params.prod_run){
            sh 'ansible-playbook site.yml -i inventory/prod.yml'
        }
        else{
            sh 'ansible-playbook site.yml -i inventory/prod.yml --check --diff'
        }
    }
}
```

Что в итоге получилось: см. [ScriptedJenkinsfile](https://github.com/Roma-EDU/vector-role/blob/1.2.1/ScriptedJenkinsfile)
P.S. playbook падает во время работы из-за отсутствия прав, но это уже к разработчику playbook'а :)

## ~Необязательная часть~

>1. Создать скрипт на groovy, который будет собирать все Job, которые завершились хотя бы раз неуспешно. Добавить скрипт в репозиторий с решением с названием `AllJobFailure.groovy`.
>2. Создать Scripted Pipeline таким образом, чтобы он мог сначала запустить через Ya.Cloud CLI необходимое количество инстансов, прописать их в инвентори плейбука и после этого запускать плейбук. Тем самым, мы должны по нажатию кнопки получить готовую к использованию систему.
