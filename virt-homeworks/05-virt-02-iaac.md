
# Домашнее задание к занятию "5.2. Применение принципов IaaC в работе с виртуальными машинами"

## Задача 1

- Опишите своими словами основные преимущества применения на практике IaaC паттернов.
- Какой из принципов IaaC является основополагающим?

**Ответ**

Преимущества:
1. Уменьшается количество ручных действий - быстрее получаем результат
2. Уходим от ошибок ручного ввода, усталости, потери внимания
3. Можно настроить конфигурации и предоставить их внешним пользователям (разработчикам). Они смогут выбрать подходящий вариант, нажать кнопку и развернуть готовую систему, не ожидая инженеров DevOps

*Основополагающий принцип*: результат всегда одинаковый, и не зависит от количества разворачиваемых виртуальных машин (идемпотентность)

## Задача 2

- Чем Ansible выгодно отличается от других систем управление конфигурациями?
- Какой, на ваш взгляд, метод работы систем конфигурации более надёжный push или pull?

**Ответ**

Преимущество Ansible в том, что он работает на существующей SSH инфраструктуре без необходимости настройки специального окружения

В моём понимании идеальным вариантом мог бы быть гибридный метод работы (push и pull), чтобы можно было как с "центрального" сервера уведомить остальных о необходимости обновиться, так и получить актуальную конфигурацию виртуальной машиной в случае, если по какой-то причине сообщение не дошло / не могло быть в данный момент обработано.
Если же выбирать только между push и pull, то на мой взгляд, pull более надёжный. При этом стоит учитывать, что система придёт в нужное состояние не сразу, а через недетерминнированный промежуток времени.

## Задача 3

Установить на личный компьютер:

- VirtualBox
- Vagrant
- Ansible

*Приложить вывод команд установленных версий каждой из программ, оформленный в markdown.*

**Ответ**

- VirtualBox
  ```console
  cd "C:\Program Files\Oracle\VirtualBox"
  vboxmanage --version
  6.1.26r145957
  ```
- Vagrant
  ```console
  vagrant --version
  Vagrant 2.2.18
  ```
- Ansible (На Windows пока не поддерживается, есть установка через Cygwin или устновка [WSL](https://docs.microsoft.com/en-us/windows/wsl/install) и накатывание Ansible на [него](https://docs.ansible.com/ansible/latest/user_guide/windows_faq.html#can-ansible-run-on-windows); документация чуть устарела, во второй строке вместо python-pip нужно указать python3-pip)
  ```bash
  ansible --version
  ansible [core 2.12.1]
    config file = None
    configured module search path = ['/home/roma/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
    ansible python module location = /home/roma/.local/lib/python3.8/site-packages/ansible
    ansible collection location = /home/roma/.ansible/collections:/usr/share/ansible/collections
    executable location = /home/roma/.local/bin/ansible
    python version = 3.8.10 (default, Nov 26 2021, 20:14:08) [GCC 9.3.0]
    jinja version = 2.10.1
    libyaml = True
   ``` 
  


## Задача 4 (*)

Воспроизвести практическую часть лекции самостоятельно.

- Создать виртуальную машину.
- Зайти внутрь ВМ, убедиться, что Docker установлен с помощью команды
```
docker ps
```

Не получается подружить Ansible (на WSL) и Vagrant (на Windows)
Вываливается вот такая ошибка (обновлять до последней версии пробовал, не помогло :((
```
Running provisioner: ansible...
Windows is not officially supported for the Ansible Control Machine.
Please check https://docs.ansible.com/intro_installation.html#control-machine-requirements
Vagrant gathered an unknown Ansible version:


and falls back on the compatibility mode '1.8'.

Alternatively, the compatibility mode can be specified in your Vagrantfile:
https://www.vagrantup.com/docs/provisioning/ansible_common.html#compatibility_mode
    server2.netology: Running ansible-playbook...
The Ansible software could not be found! Please verify
that Ansible is correctly installed on your host system.

If you haven't installed Ansible yet, please install Ansible
on your host system. Vagrant can't do this for you in a safe and
automated way.
Please check https://docs.ansible.com for more information.
```
