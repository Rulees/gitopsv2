locals {
  name = "${var.project_prefix}--${var.function_name}-${random_id.this.hex}--${var.env}"
}

resource "yandex_function_trigger" "timer" {

  description          = "Trigger Cloud Function every (*) second"
  name                 = local.name
  labels               = var.labels


  function {
    id                 = yandex_function.trigger_gitlab_deploy.id
    service_account_id = var.service_account_id
  }

  timer {
    cron_expression    = var.cron_expression
  }
}

resource "random_id" "this" {
  byte_length = 3
}