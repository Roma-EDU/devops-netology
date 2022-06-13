# 8.5. Тестирование Roles

## Подготовка к выполнению
>1. Установите molecule: `pip3 install "molecule==3.4.0"`
>2. Соберите локальный образ на основе [Dockerfile](https://github.com/netology-code/mnt-homeworks/blob/MNT-13/08-ansible-05-testing/Dockerfile)

**Ответ**: установил molecule, откатил линтер до более старой версии, собрал docker-image на основе Dockerfile для tox'а

```bash
$ pip3 install "molecule==3.4.0"
$ pip3 install molecule_docker
$ pip3 uninstall "ansible-lint"
$ pip3 install "ansible-lint<6.0.0"
```

## Основная часть

>Наша основная цель - настроить тестирование наших ролей. Задача: сделать сценарии тестирования для vector. Ожидаемый результат: все сценарии успешно проходят тестирование ролей.

### Molecule

>1. Запустите  `molecule test -s centos7` внутри корневой директории clickhouse-role, посмотрите на вывод команды.
>2. Перейдите в каталог с ролью vector-role и создайте сценарий тестирования по умолчанию при помощи `molecule init scenario --driver-name docker`.
>3. Добавьте несколько разных дистрибутивов (centos:8, ubuntu:latest) для инстансов и протестируйте роль, исправьте найденные ошибки, если они есть.
>4. Добавьте несколько assert'ов в verify.yml файл для  проверки работоспособности vector-role (проверка, что конфиг валидный, проверка успешности запуска, etc). Запустите тестирование роли повторно и проверьте, что оно прошло успешно.
>5. Добавьте новый тег на коммит с рабочим сценарием в соответствии с семантическим версионированием.

**Ответ**: 
1. С помощью `git clone git@github.com:AlexeySetevoi/ansible-clickhouse.git` копировал репозиторий [clickhouse-role](https://github.com/AlexeySetevoi/ansible-clickhouse) и запустил один тестовый сценарий `molecule test -s centos_7`
2. Добавил vector-role
   ```bash
   $ git clone git@github.com:Roma-EDU/vector-role.git
   $ cd vector-role
   $ molecule init scenario --driver-name docker
   ```
3. Заполнил разделы `platforms` и `lint` в [molecule.yml](). Запустил прогон тестов по умолчанию (папка molecule/defaults) с помощью `molecule test`, исправил перенос строк \r\n -> \n. Под centos:8 не взлетело ввиду отсутствия поддержки этой ОС (нужно специальные команды добавлять или хитрый docker-image делать)
4. Добавил проверку успешности запуска и корректности версии (2 в 1), повторно протестировал роль

### Tox

>1. Добавьте в директорию с vector-role файлы из [директории](./example)
>2. Запустите `docker run --privileged=True -v <path_to_repo>:/opt/vector-role -w /opt/vector-role -it <image_name> /bin/bash`, где path_to_repo - путь до корня репозитория с vector-role на вашей файловой системе.
>3. Внутри контейнера выполните команду `tox`, посмотрите на вывод.
>4. Создайте облегчённый сценарий для `molecule`. Проверьте его на исполнимость.
>5. Пропишите правильную команду в `tox.ini` для того чтобы запускался облегчённый сценарий.
>6. Запустите команду `tox`. Убедитесь, что всё отработало успешно.
>7. Добавьте новый тег на коммит с рабочим сценарием в соответствии с семантическим версионированием.

>После выполнения у вас должно получится два сценария molecule и один tox.ini файл в репозитории. Ссылка на репозиторий являются ответами на домашнее задание. Не забудьте указать в ответе теги решений Tox и Molecule заданий.

**Ответ**: 
1. Добавил
2. Настроил запуск docker без sudo, запустил собранный образ
   ```bash
   $ sudo groupadd docker
   $ sudo usermod -aG docker $USER
   $ sudo gpasswd -a $USER docker
   # перезапустил виртуалку и перешёл в папку с Dockerfile
   # docker build -t dind-image .
   $ docker run --privileged=True -v /vagrant/08-ansible-05-testing/vector-role:/opt/vector-role -w /opt/vector-role -it dind-image /bin/bash
   ```
3. Скопировал папку в независимый путь, т.к. иначе была ошибка
   ```bash
   $ cp . ~/test -r
   $ cd ~/test
   $ tox
   ```
4. Создал облегчённый сценарий toxtest, проверил исполнимость
5. Обновил команду в tox.ini `commands = {posargs:molecule test -s toxtest --destroy always}` для запуска этого сценария
6. Запустил, всё упало с ошибкой 
```
root@9e0b8abd5726:~/test# tox
py37-ansible211 installed: ansible==4.10.0,ansible-compat==1.0.0,ansible-core==2.11.12,ansible-lint==5.1.3,arrow==1.2.2,bcrypt==3.2.2,binaryornot==0.4.4,bracex==2.3.post1,cached-property==1.5.2,Cerberus==1.3.2,certifi==2022.5.18.1,cffi==1.15.0,chardet==4.0.0,charset-normalizer==2.0.12,click==8.1.3,click-help-colors==0.9.1,commonmark==0.9.1,cookiecutter==2.1.1,cryptography==37.0.2,distro==1.7.0,docker==5.0.3,enrich==1.2.7,idna==3.3,importlib-metadata==4.11.4,Jinja2==3.1.2,jinja2-time==0.2.0,jmespath==1.0.0,lxml==4.9.0,MarkupSafe==2.1.1,molecule==3.4.0,molecule-docker==1.1.0,packaging==21.3,paramiko==2.11.0,pathspec==0.9.0,pluggy==0.13.1,pycparser==2.21,Pygments==2.12.0,PyNaCl==1.5.0,pyparsing==3.0.9,python-dateutil==2.8.2,python-slugify==6.1.2,PyYAML==5.4.1,requests==2.28.0,resolvelib==0.5.4,rich==12.4.4,ruamel.yaml==0.17.21,ruamel.yaml.clib==0.2.6,selinux==0.2.1,six==1.16.0,subprocess-tee==0.3.5,tenacity==8.0.1,text-unidecode==1.3,typing_extensions==4.2.0,urllib3==1.26.9,wcmatch==8.4,websocket-client==1.3.2,yamllint==1.26.3,zipp==3.8.0
py37-ansible211 run-test-pre: PYTHONHASHSEED='3879655052'
py37-ansible211 run-test: commands[0] | molecule test -s toxtest --destroy always
Unable to find a working copy of ansible executable. CompletedProcess(args=['ansible', '--version'], returncode=1, stdout='', stderr='Traceback (most recent call last):\n  File "/root/test/.tox/py37-ansible211/bin/ansible", line 64, in <module>\n    from ansible.utils.display import Display, initialize_locale\n  File "/root/test/.tox/py37-ansible211/lib/python3.7/site-packages/ansible/utils/display.py", line 21, in <module>\n    import ctypes.util\n  File "/usr/local/lib/python3.7/ctypes/__init__.py", line 7, in <module>\n    from _ctypes import Union, Structure, Array\nModuleNotFoundError: No module named \'_ctypes\'\n')
ERROR: InvocationError for command /root/test/.tox/py37-ansible211/bin/molecule test -s toxtest --destroy always (exited with code 4)
py37-ansible30 installed: ansible==3.0.0,ansible-base==2.10.17,ansible-compat==1.0.0,ansible-lint==5.1.3,arrow==1.2.2,bcrypt==3.2.2,binaryornot==0.4.4,bracex==2.3.post1,cached-property==1.5.2,Cerberus==1.3.2,certifi==2022.5.18.1,cffi==1.15.0,chardet==4.0.0,charset-normalizer==2.0.12,click==8.1.3,click-help-colors==0.9.1,commonmark==0.9.1,cookiecutter==2.1.1,cryptography==37.0.2,distro==1.7.0,docker==5.0.3,enrich==1.2.7,idna==3.3,importlib-metadata==4.11.4,Jinja2==3.1.2,jinja2-time==0.2.0,jmespath==1.0.0,lxml==4.9.0,MarkupSafe==2.1.1,molecule==3.4.0,molecule-docker==1.1.0,packaging==21.3,paramiko==2.11.0,pathspec==0.9.0,pluggy==0.13.1,pycparser==2.21,Pygments==2.12.0,PyNaCl==1.5.0,pyparsing==3.0.9,python-dateutil==2.8.2,python-slugify==6.1.2,PyYAML==5.4.1,requests==2.28.0,rich==12.4.4,ruamel.yaml==0.17.21,ruamel.yaml.clib==0.2.6,selinux==0.2.1,six==1.16.0,subprocess-tee==0.3.5,tenacity==8.0.1,text-unidecode==1.3,typing_extensions==4.2.0,urllib3==1.26.9,wcmatch==8.4,websocket-client==1.3.2,yamllint==1.26.3,zipp==3.8.0
py37-ansible30 run-test-pre: PYTHONHASHSEED='3879655052'
py37-ansible30 run-test: commands[0] | molecule test -s toxtest --destroy always
INFO     toxtest scenario test matrix: create, converge, verify, destroy
INFO     Performing prerun...
INFO     Guessed /root/test as project root directory
INFO     Using /root/.cache/ansible-lint/0d5741/roles/roma_edu.vector symlink to current repository in order to enable Ansible to find the role using its expected full name.
INFO     Added ANSIBLE_ROLES_PATH=~/.ansible/roles:/usr/share/ansible/roles:/etc/ansible/roles:/root/.cache/ansible-lint/0d5741/roles
INFO     Running toxtest > create
INFO     Sanity checks: 'docker'

PLAY [Create] ******************************************************************

TASK [Log into a Docker registry] **********************************************
skipping: [localhost] => (item=None)
skipping: [localhost]

TASK [Check presence of custom Dockerfiles] ************************************
ok: [localhost] => (item={'image': 'docker.io/pycontribs/centos:7', 'name': 'centos7', 'pre_build_image': True})

TASK [Create Dockerfiles from image names] *************************************
skipping: [localhost] => (item={'image': 'docker.io/pycontribs/centos:7', 'name': 'centos7', 'pre_build_image': True})

TASK [Discover local Docker images] ********************************************
ok: [localhost] => (item={'changed': False, 'skipped': True, 'skip_reason': 'Conditional result was False', 'item': {'image': 'docker.io/pycontribs/centos:7', 'name': 'centos7', 'pre_build_image': True}, 'ansible_loop_var': 'item', 'i': 0, 'ansible_index_var': 'i'})

TASK [Build an Ansible compatible image (new)] *********************************
skipping: [localhost] => (item=molecule_local/docker.io/pycontribs/centos:7)

TASK [Create docker network(s)] ************************************************

TASK [Determine the CMD directives] ********************************************
ok: [localhost] => (item={'image': 'docker.io/pycontribs/centos:7', 'name': 'centos7', 'pre_build_image': True})

TASK [Create molecule instance(s)] *********************************************
changed: [localhost] => (item=centos7)

TASK [Wait for instance(s) creation to complete] *******************************
FAILED - RETRYING: Wait for instance(s) creation to complete (300 retries left).
failed: [localhost] (item={'started': 1, 'finished': 0, 'ansible_job_id': '973003729714.5392', 'results_file': '/root/.ansible_async/973003729714.5392', 'changed': True, 'failed': False, 'item': {'image': 'docker.io/pycontribs/centos:7', 'name': 'centos7', 'pre_build_image': True}, 'ansible_loop_var': 'item'}) => {"ansible_job_id": "973003729714.5392", "ansible_loop_var": "item", "attempts": 2, "changed": false, "finished": 1, "item": {"ansible_job_id": "973003729714.5392", "ansible_loop_var": "item", "changed": true, "failed": false, "finished": 0, "item": {"image": "docker.io/pycontribs/centos:7", "name": "centos7", "pre_build_image": true}, "results_file": "/root/.ansible_async/973003729714.5392", "started": 1}, "msg": "Unsupported parameters for (community.docker.docker_container) module: command_handling Supported parameters include: api_version, auto_remove, blkio_weight, ca_cert, cap_drop, capabilities, cgroup_parent, cleanup, client_cert, client_key, command, comparisons, container_default_behavior, cpu_period, cpu_quota, cpu_shares, cpus, cpuset_cpus, cpuset_mems, debug, default_host_ip, detach, device_read_bps, device_read_iops, device_requests, device_write_bps, device_write_iops, devices, dns_opts, dns_search_domains, dns_servers, docker_host, domainname, entrypoint, env, env_file, etc_hosts, exposed_ports, force_kill, groups, healthcheck, hostname, ignore_image, image, init, interactive, ipc_mode, keep_volumes, kernel_memory, kill_signal, labels, links, log_driver, log_options, mac_address, memory, memory_reservation, memory_swap, memory_swappiness, mounts, name, network_mode, networks, networks_cli_compatible, oom_killer, oom_score_adj, output_logs, paused, pid_mode, pids_limit, privileged, published_ports, pull, purge_networks, read_only, recreate, removal_wait_timeout, restart, restart_policy, restart_retries, runtime, security_opts, shm_size, ssl_version, state, stop_signal, stop_timeout, sysctls, timeout, tls, tls_hostname, tmpfs, tty, ulimits, user, userns_mode, uts, validate_certs, volume_driver, volumes, volumes_from, working_dir", "stderr": "/tmp/ansible_community.docker.docker_container_payload_d55tgxho/ansible_community.docker.docker_container_payload.zip/ansible_collections/community/docker/plugins/modules/docker_container.py:1193: DeprecationWarning: distutils Version classes are deprecated. Use packaging.version instead.\n", "stderr_lines": ["/tmp/ansible_community.docker.docker_container_payload_d55tgxho/ansible_community.docker.docker_container_payload.zip/ansible_collections/community/docker/plugins/modules/docker_container.py:1193: DeprecationWarning: distutils Version classes are deprecated. Use packaging.version instead."]}

PLAY RECAP *********************************************************************
localhost                  : ok=4    changed=1    unreachable=0    failed=1    skipped=4    rescued=0    ignored=0

CRITICAL Ansible return code was 2, command was: ['ansible-playbook', '--inventory', '/root/.cache/molecule/test/toxtest/inventory', '--skip-tags', 'molecule-notest,notest', '/root/test/.tox/py37-ansible30/lib/python3.7/site-packages/molecule_docker/playbooks/create.yml']
WARNING  An error occurred during the test sequence action: 'create'. Cleaning up.
INFO     Running toxtest > cleanup
WARNING  Skipping, cleanup playbook not configured.
INFO     Running toxtest > destroy

PLAY [Destroy] *****************************************************************

TASK [Destroy molecule instance(s)] ********************************************
changed: [localhost] => (item=centos7)

TASK [Wait for instance(s) deletion to complete] *******************************
FAILED - RETRYING: Wait for instance(s) deletion to complete (300 retries left).
ok: [localhost] => (item=centos7)

TASK [Delete docker networks(s)] ***********************************************

PLAY RECAP *********************************************************************
localhost                  : ok=2    changed=1    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0

INFO     Pruning extra files from scenario ephemeral directory
ERROR: InvocationError for command /root/test/.tox/py37-ansible30/bin/molecule test -s toxtest --destroy always (exited with code 1)
```

## ~Необязательная часть~

>1. Проделайте схожие манипуляции для создания роли lighthouse.
>2. Создайте сценарий внутри любой из своих ролей, который умеет поднимать весь стек при помощи всех ролей.
>3. Убедитесь в работоспособности своего стека. Создайте отдельный verify.yml, который будет проверять работоспособность интеграции всех инструментов между ними.
>4. Выложите свои roles в репозитории. В ответ приведите ссылки.

