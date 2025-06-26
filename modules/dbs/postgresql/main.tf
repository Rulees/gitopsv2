resource "yandex_mdb_postgresql_cluster" "main" {
  name        = var.cluster_name
  environment = "PRESTABLE"
  network_id  = var.network_id
  folder_id   = var.folder_id
  version     = "16"

  resources {
    resource_preset_id = "s3-c1-m4"
    disk_type_id       = "network-ssd"
    disk_size          = 20
  }

  host {
    zone      = var.zone
    subnet_id = var.subnet_id
  }

  user {
    name     = var.db_user
    password = var.db_password
  }

  database {
    name  = var.db_name
    owner = var.db_user
  }

  maintenance_window {
    type = "ANYTIME"
  }

  deletion_protection = false
}