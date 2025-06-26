variable "network_id" { type = string }
variable "subnet_id" { type = string }
variable "zone" { type = string }
variable "cluster_name" { type = string }
variable "db_name" { type = string }
variable "db_user" { type = string }
variable "db_password" { type = string sensitive = true }