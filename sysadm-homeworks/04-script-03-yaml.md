# Домашнее задание к занятию "4.3. Языки разметки JSON и YAML"


## Обязательная задача 1
Мы выгрузили JSON, который получили через API запрос к нашему сервису:
```
    { "info" : "Sample JSON output from our service\t",
        "elements" :[
            { "name" : "first",
            "type" : "server",
            "ip" : 7175 
            }
            { "name" : "second",
            "type" : "proxy",
            "ip : 71.78.22.43
            }
        ]
    }
```
  Нужно найти и исправить все ошибки, которые допускает наш сервис.
  
  Была пропущена запятая между объектами, кавычка в ключе ip и само значение тоже должно быть в кавычках
  ```json
    { 
        "info" : "Sample JSON output from our service\t",
        "elements" : [
            { 
            "name" : "first",
            "type" : "server",
            "ip" : 7175 
            }, { 
            "name" : "second",
            "type" : "proxy",
            "ip" : "71.78.22.43"
            }
        ]
    }
```

## Обязательная задача 2
В прошлый рабочий день мы создавали скрипт, позволяющий опрашивать веб-сервисы и получать их IP. К уже реализованному функционалу нам нужно добавить возможность записи JSON и YAML файлов, описывающих наши сервисы. Формат записи JSON по одному сервису: `{ "имя сервиса" : "его IP"}`. Формат записи YAML по одному сервису: `- имя сервиса: его IP`. Если в момент исполнения скрипта меняется IP у сервиса - он должен так же поменяться в yml и json файле.

### Ваш скрипт:
```python
	import time
	import socket
	import json
	import yaml

	services = ('drive.google.com', 'mail.google.com', 'google.com')
	ips = []
	is_changed = True
	services_ips = {}
	while True:
	  i = -1
	  for service in services:
		i += 1
		time.sleep(1)
		ip = socket.gethostbyname(service)
		services_ips[service] = ip
		print(f'{service} - {ip}')

		if len(ips) == i:
		  ips.append(ip)
		
		if ips[i] != ip:
		  print(f'[ERROR] {service} IP mismatch: {ips[i]} {ip}')
		  ips[i] = ip
		  is_changed = True

	  if is_changed:
		with open("services.json", "w") as json_file:
		  json_file.write(json.dumps(services_ips, indent=2))
		
		with open("services.yml", "w") as yml_file:
		  yml_file.write(yaml.dump(services_ips, explicit_start=True))
```

### Вывод скрипта при запуске при тестировании:
```
drive.google.com - 74.125.124.139
mail.google.com - 142.250.191.229
google.com - 142.250.190.46
drive.google.com - 172.217.5.14
[ERROR] drive.google.com IP mismatch: 74.125.124.139 172.217.5.14
mail.google.com - 172.217.0.37
[ERROR] mail.google.com IP mismatch: 142.250.191.229 172.217.0.37
google.com - 172.217.219.102
[ERROR] google.com IP mismatch: 142.250.190.46 172.217.219.102
drive.google.com - 142.250.191.142
[ERROR] drive.google.com IP mismatch: 172.217.5.14 142.250.191.142
mail.google.com - 142.250.191.101
[ERROR] mail.google.com IP mismatch: 172.217.0.37 142.250.191.101
google.com - 172.217.219.100
[ERROR] google.com IP mismatch: 172.217.219.102 172.217.219.100
```

### json-файл(ы), который(е) записал ваш скрипт:
```json
{
  "drive.google.com": "142.250.191.142",
  "mail.google.com": "142.250.191.101",
  "google.com": "172.217.219.100"
}
```

### yml-файл(ы), который(е) записал ваш скрипт:
```yaml
---
drive.google.com: 142.250.191.142
google.com: 172.217.219.100
mail.google.com: 142.250.191.101
```

## ~~Дополнительное задание (со звездочкой*) - необязательно к выполнению~~

~~Так как команды в нашей компании никак не могут прийти к единому мнению о том, какой формат разметки данных использовать: JSON или YAML, нам нужно реализовать парсер из одного формата в другой. Он должен уметь:~~
   * Принимать на вход имя файла
   * Проверять формат исходного файла. Если файл не json или yml - скрипт должен остановить свою работу
   * Распознавать какой формат данных в файле. Считается, что файлы *.json и *.yml могут быть перепутаны
   * Перекодировать данные из исходного формата во второй доступный (из JSON в YAML, из YAML в JSON)
   * При обнаружении ошибки в исходном файле - указать в стандартном выводе строку с ошибкой синтаксиса и её номер
   * Полученный файл должен иметь имя исходного файла, разница в наименовании обеспечивается разницей расширения файлов
