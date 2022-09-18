provider "yandex" {
  service_account_key_file = "key.json"
  cloud_id  = var.yandex_cloud_id
  folder_id = var.yandex_folder_id
  zone      = var.yandex_zone
}

resource "yandex_compute_instance" "control-plane-vm" {
  count     = 1
  zone      = var.yandex_zone
  allow_stopping_for_update = true
  name      = "cp${count.index+1}"

  resources {
    cores  = 2
    memory = 4
  }

  lifecycle {
    create_before_destroy = true
  }

  boot_disk {
    initialize_params {
      image_id = var.container_optimized_image
      type     = "network-nvme"
      size     = 30
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


resource "yandex_compute_instance" "worker-node-vm" {
  count     = 4
  zone      = var.yandex_zone
  allow_stopping_for_update = true
  name      = "node${count.index + 1}"
  
  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.container_optimized_image
      type     = "network-nvme"
      size     = 30
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