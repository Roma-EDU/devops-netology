provider "yandex" {
  service_account_key_file = file("../secrets/key.json")
  cloud_id  = var.yandex_cloud_id
  folder_id = var.yandex_folder_id
  zone      = var.yandex_zone
}


#==================================================

# 1. Общая VPC
resource "yandex_vpc_network" "network-1" {
  name        = "netology-network"
  description = "VPC Организация проекта при помощи облачных провайдеров"
}


#==================================================

# 2.1. Публичная подсеть
resource "yandex_vpc_subnet" "subnet-public-1" {
  name           = "public"
  zone           = var.yandex_zone
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

# 2.2. NAT инстанс (не шлюз) в публичной подсети с фиксированным внутренним IP 
resource "yandex_compute_instance" "nat-vm-1" {
  name                      = "nat-vm"
  allow_stopping_for_update = true
  platform_id               = "standard-v3"
  zone                      = var.yandex_zone

  resources {
    cores         = 2
    memory        = 1
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = var.clopro_homeworks_image
      type     = "network-ssd"
      size     = 8
    }
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.subnet-public-1.id
    nat        = true                 # Выдаём публичный IP
    ip_address = var.nat_internal_ip  # Фиксируем внутренний IP согласно ТЗ
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_ed25519.pub")}"
  }

  # Прерываемая
  scheduling_policy {
    preemptible = true
  }
}

# 2.3. Инстанс в публичной подсети с публичный IP
resource "yandex_compute_instance" "public-vm-1" {
  name                      = "public-vm"
  allow_stopping_for_update = true
  platform_id               = "standard-v3"
  zone                      = var.yandex_zone

  resources {
    cores         = 2
    memory        = 1
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = var.ubuntu_2204
      type     = "network-ssd"
      size     = 8
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-public-1.id
    nat       = true  # Выдаём публичный IP
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_ed25519.pub")}"
  }

  # Прерываемая
  scheduling_policy {
    preemptible = true
  }
}


#==================================================

# 3.1. Приватная подсеть (с привязкой к таблице маршрутизации)
resource "yandex_vpc_subnet" "subnet-private-1" {
  name           = "private"
  zone           = var.yandex_zone
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.20.0/24"]
  route_table_id = yandex_vpc_route_table.nat-instance-route.id
}

# 3.2. Таблица маршрутизации со статическим маршрутом
resource "yandex_vpc_route_table" "nat-instance-route" {
  name       = "private-route-table"
  network_id = yandex_vpc_network.network-1.id
  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = yandex_compute_instance.nat-vm-1.network_interface.0.ip_address
  }
}

# 3.3. Инстанс в приватной подсети
resource "yandex_compute_instance" "private-vm-1" {
  name                      = "private-vm"
  allow_stopping_for_update = true
  platform_id               = "standard-v3"
  zone                      = var.yandex_zone

  resources {
    cores         = 2
    memory        = 1
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = var.ubuntu_2204
      type     = "network-ssd"
      size     = 8
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-private-1.id
    nat       = false  # Нет публичного IP
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_ed25519.pub")}"
  }

  # Прерываемая
  scheduling_policy {
    preemptible = true
  }
}


