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
  folder_id = "b1ghomnle3pg309t5gu0"
  cloud_id  = "b1gle99ifk9rj88rn6h0"
}