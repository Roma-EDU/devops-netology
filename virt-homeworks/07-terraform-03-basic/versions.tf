# Provider https://cloud.yandex.ru/docs/tutorials/infrastructure-management/terraform-quickstart
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"

  backend "s3" {
    endpoint   = "storage.yandexcloud.net"
    bucket     = "terraform-object-storage-tutorial-unique-xsas23"
    region     = "ru-central1-a"
    key        = "states/terraform.tfstate"
    access_key = ""
    secret_key = ""

    skip_region_validation      = true
    skip_credentials_validation = true
  }
}