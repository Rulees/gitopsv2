# FOR CONNECTION
output "db_engine" {
  description = "What BD is used?"
  value       = "postgresql"
}

output "db_login" {
  description = "login for atlas to connect with db"
  value       = var.db_login
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

output "cluster_master_fqdn" {
  description = "fqdn of db for atlas"
  value       = "c-${yandex_mdb_postgresql_cluster_v2.this.id}.rw.mdb.yandexcloud.net"
  sensitive   = true
}

output "db_name" {
  description = "name for atlase to connect with db"
  value       = yandex_mdb_postgresql_database.this.name
  sensitive   = true
}