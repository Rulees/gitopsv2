# FOR CONNECTION
output "db_engine" {
  description = "user for atlas to connect with db"
  value       = "postgresql"
}

output "db_user" {
  description = "user for atlas to connect with db"
  value       = var.db_user
  sensitive   = true
}

output "db_password" {
  description = "password for atlas to connect with db"
  value       = var.db_password
  sensitive   = true
}

output "db_port" {
  description = "database port for atlas to connect with db"
  value       = "6432"
}

output "claster_master_fqdn" {
  description = ""
  value       = "${yandex_mdb_postgresql_cluster.main.id}.rw.mdb.yandexcloud.net"
  sensitive   = true
}

output "db_name" {
  description = "password for atlas to connect with db"
  value       = yandex_mdb_postgresql_database.this.name
  sensitive   = true
}