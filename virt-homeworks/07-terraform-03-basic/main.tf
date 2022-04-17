provider "yandex" {
  service_account_key_file = "key.json"
  cloud_id  = var.yandex_cloud_id
  folder_id = var.yandex_folder_id
  zone      = var.yandex_zone
}

locals {
  is_prod = terraform.workspace == "prod"
  memory_map = {
    default  = 4
    prod     = 8
    stage    = 2
  }
  monitoring_map = {
    prod     = ["m1"]
    stage    = []
  }
}

resource "yandex_compute_instance" "site-vm" {
  zone      = var.yandex_zone
  allow_stopping_for_update = true
  count     = local.is_prod ? 2 : 1

  resources {
    cores  = local.is_prod ? 4 : 2
    memory = local.memory_map[terraform.workspace]
  }

  lifecycle {
    create_before_destroy = true
  }

  boot_disk {
    initialize_params {
      image_id = var.ubuntu_2004
      type     = "network-nvme"
      size     = local.is_prod ? "20" : "10"
    }
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.subnet-1.id
    nat        = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}


resource "yandex_compute_instance" "monitoring-vm" {
  for_each  = toset( local.monitoring_map[terraform.workspace] )
  zone      = var.yandex_zone
  allow_stopping_for_update = true
  
  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.ubuntu_2004
      type     = "network-nvme"
      size     = 10
    }
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.subnet-1.id
    nat        = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}