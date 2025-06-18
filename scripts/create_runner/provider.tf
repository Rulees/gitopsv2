terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
      version = "= 0.141.0"
    }
  }
  required_version = ">= 1.9.4"
}

provider "yandex" {
  zone      = "ru-central1-a"
  folder_id = "b1g1s1l8qr1m59f3orlt"
  cloud_id  = "b1g6lfsqbtpq384k0vrj"
}