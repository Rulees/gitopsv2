variable "project_prefix" {
  description        = "Name prefix of project."
  type               = string
}

variable "env" {
  description        = "Set 'prod' for production, or 'dev' for development"
  type               = string
}

variable "container_registry_name" {
  description = "Name of the Yandex Container Registry"
  type        = string
  default     = "registry"
}
