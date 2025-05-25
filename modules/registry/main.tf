resource "yandex_container_registry" "this" {
  name      = "${var.project_prefix}--${var.container_registry_name}--${var.env}"
}