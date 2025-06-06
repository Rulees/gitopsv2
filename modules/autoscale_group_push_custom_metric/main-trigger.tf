locals {
  name = "${var.project_prefix}--${var.trigger_name}--${var.env}"
}

resource "yandex_function_trigger" "timer" {

  description          = "Trigger Cloud Function to push custom metric every 12 seconds"
  name                 = local.name


  function {
    id                 = yandex_function.push_metric.id
    service_account_id = var.service_account_id
  }

  timer {
    cron_expression    = var.cron_expression
  }
}
