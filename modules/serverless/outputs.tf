output "container_id" { #
  description          = "ID of Serverless Container"
  value                = yandex_serverless_container.this.id
}

output "container_last_revision_id" {
  description          = "Last revision ID of Serverless Container"
  value                = yandex_serverless_container.this.revision_id
}

output "container_url" {
  description          = "Invoke URL for Serverless Container"
  value                = yandex_serverless_container.this.url
}

output "image_url" {
  value                = var.image_url
}

output "container_resources" {
  description          = "All resource-related configuration for reuse in trigger or other modules."
  value = {
    container_id       = yandex_serverless_container.this.id
    description        = "${var.project_prefix} container for ${var.env} environment"

    resources = {
      memory           = var.memory * 1024 * 1024
      cores            = var.cores
      core_fraction    = var.core_fraction
    }

    execution_timeout  = var.execution_timeout
    service_account_id = var.service_account_id

    image_spec = {
      image_url        = var.image_url
    }

    concurrency        = var.concurrency

    connectivity = {
      network_id       = var.network_id
    }

    provision_policy = {
      min_instances    = var.min_instances
    }
  }
}
