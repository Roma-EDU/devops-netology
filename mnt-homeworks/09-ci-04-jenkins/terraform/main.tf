provider "yandex" {
  service_account_key_file = "key.json"
  cloud_id  = var.yandex_cloud_id
  folder_id = var.yandex_folder_id
  zone      = var.yandex_zone
}

resource "yandex_compute_instance" "jenkins-master-01" {
  name      = "jenkins-master-01-server"
  zone      = var.yandex_zone
  hostname  = "jenkins-master-01.netology.yc"
  allow_stopping_for_update = true

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = var.os_image_id
      type     = "network-nvme"
      size     = "10"
    }
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.subnet-1.id
    nat        = true
    ip_address = "192.168.10.11"
  }

  metadata = {
    ssh-keys = "${var.os_user}:${file("~/.ssh/id_rsa.pub")}"
  }
}

resource "yandex_compute_instance" "jenkins-agent-01" {
  name      = "jenkins-agent-01-server"
  zone      = var.yandex_zone
  hostname  = "jenkins-agent-01.netology.yc"
  allow_stopping_for_update = true

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = var.os_image_id
      type     = "network-nvme"
      size     = "10"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
    ip_address = "192.168.10.21"
  }

  metadata = {
    ssh-keys = "${var.os_user}:${file("~/.ssh/id_rsa.pub")}"
  }
}
