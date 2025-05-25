locals {
  name = "${var.project_prefix}--${var.container_name}--${var.env}"
}

resource "yandex_serverless_container" "this" {
  # GENERAL
  description                     = "${var.project_prefix} container for ${var.env} environment"
  connectivity {network_id        = var.network_id}
  service_account_id              = var.service_account_id
  runtime {type                   = var.runtime_type}
  labels                          = var.labels
  
  # RESOURCES
  name                            = local.name
  image {url                      = var.image_url}
  cores                           = var.cores
  core_fraction                   = var.core_fraction
  memory                          = var.memory
  concurrency                     = var.concurrency
  provision_policy {min_instances = var.min_instances}
  execution_timeout               = var.execution_timeout
}

resource "yandex_serverless_container_iam_binding" "make_it_public" {
  count        = var.public ? 1 : 0
  
  container_id = yandex_serverless_container.this.id
  role         = "serverless.containers.invoker"
  members      = ["system:allUsers"]
}