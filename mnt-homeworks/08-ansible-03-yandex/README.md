# 8.3. Использование Yandex Cloud

**Ответ**: ссылка на [ветку в другом репозитории](https://github.com/Roma-EDU/ansible-netology/tree/08-ansible-03-yandex)

## Подготовка к выполнению

- [x] Подготовьте в Yandex Cloud три хоста: для `clickhouse`, для `vector` и для `lighthouse`.

Подробное описание шагов подготовки (инициализация Yandex.Cloud, создание виртуалок с помощью Terraform, и т.п.) см. в предыдущем ДЗ [08-ansible-02-playbook](https://github.com/Roma-EDU/devops-netology/tree/master/mnt-homeworks/08-ansible-02-playbook)

## Основная часть

1. Допишите playbook: нужно сделать ещё один play, который устанавливает и настраивает lighthouse.
   - **Ответ**: добавил play для установки lighthouse и веб-сервера nginx для его работы
2. При создании tasks рекомендую использовать модули: `get_url`, `template`, `yum`, `apt`.
   - **Ответ**: получилось реализовать с помощью встроенных команд `yum`, `template` и `git`
3. Tasks должны: скачать статику lighthouse, установить nginx или любой другой webserver, настроить его конфиг для открытия lighthouse, запустить webserver.
   - **Ответ**: сделано
4. Приготовьте свой собственный inventory файл `prod.yml`.
   - **Ответ**: исправил (дополнил новыми play) inventory файл `prod.yml` из проошлого ДЗ
5. Запустите `ansible-lint site.yml` и исправьте ошибки, если они есть.
   - **Ответ**: запустил `ansible-lint site.yml`, исправил потерянные кавычки, полное название команд `ansible.builtin.` и новую строку в конце
6. Попробуйте запустить playbook на этом окружении с флагом `--check`.
   - **Ответ**: попробовал `ansible-playbook -i inventory/prod.yml site.yml --check`, часть шагов выполнилась (но не все, т.к. не были скачаны файлы)
7. Запустите playbook на `prod.yml` окружении с флагом `--diff`. Убедитесь, что изменения на системе произведены.
   - **Ответ**: запустил `ansible-playbook -i inventory/prod.yml site.yml --diff`, увидел внесённые изменения
8. Повторно запустите playbook с флагом `--diff` и убедитесь, что playbook идемпотентен.
   - **Ответ**: повторно запустил `ansible-playbook -i inventory/prod.yml site.yml --diff`, все шаги зелёные (статус ok, изменения не требуются)
9. Подготовьте README.md файл по своему playbook. В нём должно быть описано: что делает playbook, какие у него есть параметры и теги.
   - **Ответ**: подготовил, см. другой репозиторий с тегом [08-ansible-03-yandex](https://github.com/Roma-EDU/ansible-netology/tree/08-ansible-03-yandex)
10. Готовый playbook выложите в свой репозиторий, поставьте тег `08-ansible-03-yandex` на фиксирующий коммит, в ответ предоставьте ссылку на него.
   - **Ответ**: обновил содержимое репозитория из прошлого ДЗ, проставил тег
