locals {
  name = "${var.project_prefix}--${var.trigger_name}--${var.env}"
}

resource "yandex_function_trigger" "restart_container" {

  description          = "Trigger function to restart container on image push with tag 'latest'"
  name                 = local.name

  function {
    id                 = yandex_function.restart_container.id
    service_account_id = var.service_account_id
  }
  container_registry {
    create_image_tag   = var.create_image_tag
    registry_id        = var.registry_id
    image_name         = var.image_name
    tag                = var.image_tag
    batch_cutoff       = var.batch_cutoff
    batch_size         = var.batch_size
  }
}