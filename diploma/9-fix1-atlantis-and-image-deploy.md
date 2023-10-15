# Доработки по [дипломному проекту](./..diploma)

1. Добавить Atlantis
2. Добавить деплой Docker-образа в кластер Kubernetes при создании тега

## 1. Добавление Atlantis

Для отслеживания изменения инфрастуктуры было выбрано разворачивание Atlantis'а на отдельную машину согласно [документации](https://www.runatlantis.io/docs/installation-guide.html)

**Основные моменты**:

В облаке в отдельной сети развёрнута ещё одна машина с публичным IP
```yaml
provider "yandex" {
  service_account_key_file = file("../secrets/key.json")
  cloud_id  = var.yandex_cloud_id
  folder_id = var.yandex_folder_id
  zone      = var.yandex_zone
}

# 1. Service apps network
resource "yandex_vpc_network" "sevice-network" {
  name        = "my-service-network"
  description = "Service apps VPC"
}
resource "yandex_vpc_subnet" "service-subnet" {
  name           = "my-service-subnet"
  zone           = var.yandex_zone
  network_id     = yandex_vpc_network.sevice-network.id
  v4_cidr_blocks = ["10.90.0.0/24"]
  depends_on     = [
    yandex_vpc_network.sevice-network,
  ]
}

# 2. Service vm
resource "yandex_compute_instance" "service-apps-vm" {
  name      = "service-apps"
  zone      = var.yandex_zone
  allow_stopping_for_update = true

  resources {
    cores  = 2
    memory = 4
  }

  lifecycle {
    create_before_destroy = true
  }

  boot_disk {
    initialize_params {
      image_id = var.ubuntu_2204
      type     = "network-nvme"
      size     = 30
    }
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.service-subnet.id
    nat        = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

# 3. Public IPs
output "external_ip_address_service-apps-vm" {
  value = yandex_compute_instance.service-apps-vm.network_interface.0.nat_ip_address
}
```

На неё установлены/обновлены приложения
* terraform (1.5.7 - та же версия, с помощью которой разворачивается кластер)
* unzip, git, ngrok
* atlantis (скачан в виде бинарника и положен в /usr/bin)

Добавлен файл `~/.terraformrc`
```
provider_installation {
  network_mirror {
    url = "https://terraform-mirror.yandexcloud.net/"
    include = ["registry.terraform.io/*/*"]
  }
  direct {
    exclude = ["registry.terraform.io/*/*"]
  }
}
```

И скопированы "секретные" файлы
* ~/.authorized_key.json (ключ от сервисного аккаунта yc для терраформ)
* ~/.ssh/id_rsa.pub (публичный ключ для доступа по ssh к установливаемым машинам кластера)

Кроме того, добавлен серверный файл конфигурации `/opt/atlantis/repos.yaml`, чтобы получить доступ к бакету с хранилищем состояния терраформа
```yaml
# repos.yaml
repos:
- id: "github.com/Roma-EDU/diploma-infrastructure"
  workflow: ycworkflow
workflows:
  ycworkflow:
    plan:
      steps:
      - env:
          name: ACCESS_KEY
          value: <MY_ACCESS_KEY>
      - env:
          name: SECRET_KEY
          value: <MY_SECRET_KEY>
      - run:
          command: terraform init -backend-config="access_key=${ACCESS_KEY}" -backend-config="secret_key=${SECRET_KEY}"
      - plan
    apply:
      steps:
      - apply
```

Сам Atlantis добавлен как служба `/etc/systemd/system/atlantis.service`
```
[Unit]
Description=Atlantis

[Service]
User=ubuntu
Group=ubuntu
Restart=on-failure
ExecStart=/usr/bin/atlantis server \
--atlantis-url="http://130.193.49.58:4141" \
--gh-user="Roma-EDU" \
--gh-token="<PERSONAL_GITHUB_TOKEN>" \
--gh-webhook-secret="<WEBHOOK_SECRET>" \
--repo-allowlist="github.com/Roma-EDU/diploma-infrastructure" \
--repo-config="/opt/atlantis/repos.yaml"

[Install]
WantedBy=multi-user.target
```

И соответственно перезапущены службы
```bash
$ sudo systemctl daemon-reload
$ sudo systemctl start atlantis.service
$ sudo systemctl enable atlantis.service
$ systemctl status atlantis.service
```
