output "registry_id" {
  description = "ID of Container Registry"
  value       = yandex_container_registry.this.id
}

output "registry_name" {
  description = "NAME of Container Registry"
  value       = yandex_container_registry.this.name
}