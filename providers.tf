terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  service_account_key_file = var.service_account_key
  cloud_id                 = var.cloudid
  folder_id                = var.folderid
  zone                     = var.zone
}