##
# DEFAULTS
##

variable "project_prefix" {
  description = "Prefix for naming"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "labels" {
  description = "cluster labels"
  type        = map(string)
  default     = {}
}

variable "network_id" {
  description = "Network(vpc) id"
  type        = string
}

variable "zone" {
  description = "The availability zone where cluster will be created"
  type        = string
}

variable "subnet_id" {
  description = ""
  type        = string
}

##
# CLUSTER
##

variable "cluster_name" {
  description = "Custom name for database"
  type        = string
}

variable "cluster_environment" {
  description = "PRESTABLE or PRODUCTION env"
  type        = string
}

variable "db_version" {
  description = "Postresql version"
  type        = number
}

variable "assign_public_ip" {
  description = "Allow/Restric public access"
  type        = bool
  default     = false
}

# CONFIG

variable "disk_size" {
  description = ""
  type        = number
}

variable "disk_type_id" {
  description = ""
  type        = string
}

variable "resource_preset_id" {
  description = ""
  type        = string
}


##
# USER
##

variable "db_login" {
  description = "Username for Database user owner"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Password for Database user owner"
  type        = string
  sensitive   = true
}

##
# DATABASE
##

variable "db_name" {
  description = "Custom name for database"
  type        = string
}
