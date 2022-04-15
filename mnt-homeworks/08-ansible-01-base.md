# 8.1. Введение в Ansible

## Подготовка к выполнению

>1. Установите ansible версии 2.10 или выше
>1. Создайте свой собственный публичный репозиторий на github с произвольным именем.
>1. Скачайте [playbook](./playbook/) из репозитория с домашним заданием и перенесите его в свой репозиторий.

### Шаг 1. Установка docker (пригодится для развёртывания отдельных хостов)

Согласно официальному мануалу [docker](https://docs.docker.com/engine/install/ubuntu/) и до кучи [docker-compose](https://docs.docker.com/compose/install/)
```bash
$ sudo apt-get update
$ sudo apt-get install ca-certificates curl gnupg lsb-release
$ curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
$ echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
$ sudo apt-get update
$ sudo apt-get install docker-ce docker-ce-cli containerd.io

$ sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
$ sudo chmod +x /usr/local/bin/docker-compose
```

Cкачивание и запуск образов с именами, соответствующие используемым в дальнейшем хостам `ubuntu` и `centos7`

```bash
$ sudo docker pull pycontribs/ubuntu
Using default tag: latest
...
docker.io/pycontribs/ubuntu:latest
$ sudo docker pull pycontribs/centos:7
7: Pulling from pycontribs/centos
...
docker.io/pycontribs/centos:7
$ sudo docker image ls
REPOSITORY          TAG       IMAGE ID       CREATED         SIZE
pycontribs/centos   7         bafa54e44377   11 months ago   488MB
pycontribs/ubuntu   latest    42a4e3b21923   2 years ago     664MB
$ sudo docker run -itd --name ubuntu 42a4e3b21923
5f510af71a18a2bbf33ec0fd149e32556bc3229083a5d8caa3379b013d564a41
$ sudo docker run -itd --name centos7 bafa54e44377
c56ff287996a39e897c48dd07da20a40ec0afeb306a96f84e70920e782a57672
$ sudo docker container ls
CONTAINER ID   IMAGE          COMMAND       CREATED              STATUS              PORTS     NAMES
c56ff287996a   bafa54e44377   "/bin/bash"   4 seconds ago        Up 3 seconds                  centos7
5f510af71a18   42a4e3b21923   "/bin/bash"   About a minute ago   Up About a minute             ubuntu
```

### Шаг 2. Установка ansible

Docker работает из-под рута (либо из-под пользователя, входящего в специальную группу docker с настроенными правами). Поэтому чтобы ansible 
нормально с ним взаимодействовал, дальше придётся работать из-под `sudo`. 
Устанавливать будем согласно документации [ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#installing-and-upgrading-ansible-with-pip) 
(для текущего пользователя - с ключом `--user`)

```bash
$ sudo -i
$ curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
$ python3 get-pip.py
$ python3 -m pip install ansible
$ export PATH=$PATH:/root/.local/bin
$ ansible --version
ansible [core 2.12.4]
  config file = None
  configured module search path = ['/root/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
  ansible python module location = /root/.local/lib/python3.8/site-packages/ansible
  ansible collection location = /root/.ansible/collections:/usr/share/ansible/collections
  executable location = /root/.local/bin/ansible
  python version = 3.8.10 (default, Nov 26 2021, 20:14:08) [GCC 9.3.0]
  jinja version = 2.10.1
  libyaml = True
```

**Вопрос**: может можно настроить/запускать ansible как-то иначе? Пробовал дополнительный параметр `become: true`, не помогло
>fatal: [centos7]: FAILED! => {"msg": "Docker version check (['/usr/bin/docker', 'version', '--format', \"'{{.Server.Version}}'\"]) failed: Got 
>permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: 
>Get \"http://%2Fvar%2Frun%2Fdocker.sock/v1.24/version\": dial unix /var/run/docker.sock: connect: permission denied\n"}


### Шаг 3. Скачиваем артифакты и переходим в рабочую папку

С помощью сервиса [DownGit](https://minhaskamal.github.io/DownGit/#/home) выкачиваем папку с исходниками [playbook](https://github.com/netology-code/mnt-homeworks/tree/MNT-7/08-ansible-01-base/playbook) и кладём в шаренную папку, затем на виртуальной машине переходим в неё `cd /vagrant/08-ansible-01-base`



## Основная часть
1. Попробуйте запустить playbook на окружении из `test.yml`, зафиксируйте какое значение имеет факт `some_fact` для указанного хоста при выполнении playbook'a.
   * Команда для запуска `ansible-playbook -i inventory/test.yml site.yml`, значение `some_fact` = 12
   ```bash
   $ ansible-playbook -i inventory/test.yml site.yml
   
   PLAY [Print os facts] **************************************************************************************************
   
   TASK [Gathering Facts] *************************************************************************************************
   ok: [localhost]
   
   TASK [Print OS] ********************************************************************************************************
   ok: [localhost] => {
       "msg": "Ubuntu"
   }
   
   TASK [Print fact] ******************************************************************************************************
   ok: [localhost] => {
       "msg": 12
   }
   
   PLAY RECAP *************************************************************************************************************
   localhost                  : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
   ```
1. Найдите файл с переменными (group_vars) в котором задаётся найденное в первом пункте значение и поменяйте его на 'all default fact'.
   * Переменная взялась из `group_vars/all/examp.yml`, так как более специфичного окружения нет
1. Воспользуйтесь подготовленным (используется `docker`) или создайте собственное окружение для проведения дальнейших испытаний.
   * Запущены ранее `sudo docker run -itd --name ubuntu 42a4e3b21923` и `sudo docker run -itd --name centos7 bafa54e44377`
1. Проведите запуск playbook на окружении из `prod.yml`. Зафиксируйте полученные значения `some_fact` для каждого из `managed host`.
   * Запуск командой `ansible-playbook -i inventory/prod.yml site.yml`, значения переменной `some_fact` = deb и el
   ```bash
   PLAY [Print os facts] **************************************************************************************************
   
   TASK [Gathering Facts] *************************************************************************************************
   ok: [ubuntu]
   ok: [centos7]
   
   TASK [Print OS] ********************************************************************************************************
   ok: [centos7] => {
       "msg": "CentOS"
   }
   ok: [ubuntu] => {
       "msg": "Ubuntu"
   }
   
   TASK [Print fact] ******************************************************************************************************
   ok: [ubuntu] => {
       "msg": "deb"
   }
   ok: [centos7] => {
       "msg": "el"
   }
   
   PLAY RECAP *************************************************************************************************************
   centos7                    : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
   ubuntu                     : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
   ```
1. Добавьте факты в `group_vars` каждой из групп хостов так, чтобы для `some_fact` получились следующие значения: для `deb` - 'deb default fact', для `el` - 'el default fact'.
   * Переопределил значение переменной `some_fact` в файликах `group_vars/deb/examp.yml` и `group_vars/el/examp.yml`
1. Повторите запуск playbook на окружении `prod.yml`. Убедитесь, что выдаются корректные значения для всех хостов.
   * Повторил команду `ansible-playbook -i inventory/prod.yml site.yml`, значения переменной `some_fact` = 'deb default fact' и 'el default fact'
1. При помощи `ansible-vault` зашифруйте факты в `group_vars/deb` и `group_vars/el` с паролем `netology`.
   * Здесь немного разнообразил, зашифровав целый файл `ansible-vault encrypt ./group_vars/el/examp.yml` и отдельно переменную some_fact `ansible-vault encrypt_string 'PaSSw0rd' --name 'some_fact'` общим паролем `netology`
   ```bash
    $ ansible-vault encrypt ./group_vars/el/examp.yml
    New Vault password:
    Confirm New Vault password:
    Encryption successful
    $ ansible-vault encrypt_string 'PaSSw0rd' --name 'some_fact'
    New Vault password:
    Confirm New Vault password:
    some_fact: !vault |
              $ANSIBLE_VAULT;1.1;AES256
              34636662303432386135643733356637333864643061333133613937666466333762643863653730
              3664303462326131303064363836333436633930323863310a643635393739623864363661623264
              31626166363363653038303231343565646130386565363438396336626230663233353962303564
              3564336135366665320a363164303761653034343338326166623239326265633361643538353962
              3663
    Encryption successful
   ```
1. Запустите playbook на окружении `prod.yml`. При запуске `ansible` должен запросить у вас пароль. Убедитесь в работоспособности.
   * Запустил с параметром `--ask-vault-pass` для запроса пароля `ansible-playbook -i inventory/prod.yml site.yml --ask-vault-pass`
   ```bash
   $ ansible-playbook -i inventory/prod.yml site.yml --ask-vault-pass
   Vault password:
   
   PLAY [Print os facts] **************************************************************************************************
   
   TASK [Gathering Facts] *************************************************************************************************
   ok: [ubuntu]
   ok: [centos7]
   
   TASK [Print OS] ********************************************************************************************************
   ok: [centos7] => {
       "msg": "CentOS"
   }
   ok: [ubuntu] => {
       "msg": "Ubuntu"
   }
   
   TASK [Print fact] ******************************************************************************************************
   ok: [centos7] => {
       "msg": "el default fact"
   }
   ok: [ubuntu] => {
       "msg": "PaSSw0rd"
   }
   
   PLAY RECAP *************************************************************************************************************
   centos7                    : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
   ubuntu                     : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
   ```
1. Посмотрите при помощи `ansible-doc` список плагинов для подключения. Выберите подходящий для работы на `control node`.
   * С помощью команды для получения списка плагинов для подключения `ansible-doc -t connection -l` нашёл `local` с описанием `execute on controller`
1. В `prod.yml` добавьте новую группу хостов с именем  `local`, в ней разместите localhost с необходимым типом подключения.
   * Добавил 
   ```yml
   local:
     hosts:
       localhost:
         ansible_connection: local
   ```
5. Запустите playbook на окружении `prod.yml`. При запуске `ansible` должен запросить у вас пароль. Убедитесь что факты `some_fact` для каждого из хостов определены из верных `group_vars`.
6. Заполните `README.md` ответами на вопросы. Сделайте `git push` в ветку `master`. В ответе отправьте ссылку на ваш открытый репозиторий с изменённым `playbook` и заполненным `README.md`.

## Необязательная часть

1. При помощи `ansible-vault` расшифруйте все зашифрованные файлы с переменными.
2. Зашифруйте отдельное значение `PaSSw0rd` для переменной `some_fact` паролем `netology`. Добавьте полученное значение в `group_vars/all/exmp.yml`.
3. Запустите `playbook`, убедитесь, что для нужных хостов применился новый `fact`.
4. Добавьте новую группу хостов `fedora`, самостоятельно придумайте для неё переменную. В качестве образа можно использовать [этот](https://hub.docker.com/r/pycontribs/fedora).
5. Напишите скрипт на bash: автоматизируйте поднятие необходимых контейнеров, запуск ansible-playbook и остановку контейнеров.
6. Все изменения должны быть зафиксированы и отправлены в вашей личный репозиторий.
