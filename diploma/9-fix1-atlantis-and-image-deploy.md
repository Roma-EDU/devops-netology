# Доработки по [дипломному проекту](./..diploma)

1. Добавить Atlantis
2. Добавить деплой Docker-образа в кластер Kubernetes при создании тега

## Добавление Atlantis

Для отслеживания изменения инфрастуктуры было выбрано разворачивание Atlantis'а на отдельную машину согласно [документации](https://www.runatlantis.io/docs/installation-guide.html)
1. В облаке в отдельной сети развёрнута ещё одна машина с публичным IP
```yml
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
3. 
