# ID своего облака
# https://console.cloud.yandex.ru/cloud?section=overview
variable "yandex_cloud_id" {
  default = "b1gjn3v7sno758hjjba0"
}

# Folder своего облака
# https://console.cloud.yandex.ru/cloud?section=overview
variable "yandex_folder_id" {
  default = "b1gr1vdb5g3ktr8v0877"
}

# ID образа
# ID можно узнать с помощью команды yc compute image list
# Или взять из списка существующих https://console.cloud.yandex.ru/folders/b1gr1vdb5g3ktr8v0877/compute/create-instance
# нажав на i и прокрутив вниз до image_id
variable "ubuntu_2004" {
  default = "fd8mfc6omiki5govl68h"
}
variable "container_optimized_image" {
  default = "fd80o2eikcn22b229tsa"
}

variable "yandex_zone" {
  default = "ru-central1-a"
}