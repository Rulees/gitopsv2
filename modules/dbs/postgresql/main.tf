locals {
  db_name              = "${var.project_prefix}--${var.db_name}-${random_id.this.hex}--${var.env}"
  cluster_name         = "${var.project_prefix}--${var.cluster_name}-${random_id.this.hex}--${var.env}"
}


resource "yandex_mdb_postgresql_cluster_v2" "this" {
  # GENERAL
  name                 = local.cluster_name
  description          = "${var.project_prefix} database cluster for ${var.env} environment"
  network_id           = var.network_id


  # CLUSTER
  environment          = var.cluster_environment
  config {
    version            = var.db_version
    resources {
      disk_size          = var.disk_size
      disk_type_id       = var.disk_type_id
      resource_preset_id = var.resource_preset_id
    }
  }
  hosts = {
    default = {
      zone             = var.zone
      subnet_id        = var.subnet_id
      assign_public_ip = var.assign_public_ip
    }
  }
}

# USER
resource "yandex_mdb_postgresql_user" "this" {
  cluster_id           = yandex_mdb_postgresql_cluster_v2.this.id
  name                 = var.db_login
  password             = var.db_password
}

# DATABASE
resource "yandex_mdb_postgresql_database" "this" {
  cluster_id           = yandex_mdb_postgresql_cluster_v2.this.id
  name                 = var.db_name
  owner                = yandex_mdb_postgresql_user.this.name
}

resource "random_id" "this" {
  byte_length          = 3
}
