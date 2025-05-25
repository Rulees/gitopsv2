locals {
  name                     = "${var.project_prefix}--${var.api_gateway_name}--${var.env}"
  spec                     = templatefile("${path.module}/openapi.tmp.yml", {
    container_id           = var.container_id
    service_account_id     = var.service_account_id
  })
}

resource "yandex_api_gateway" "this" {
  # GENERAL
  description              = "${var.project_prefix} GatewayAPI for ${var.env} environment"
  labels                   = var.labels
  connectivity {network_id = var.network_id}
  spec                     = local.spec


  # RESOURCES
  name                     = local.name
  execution_timeout        = var.execution_timeout

  dynamic "custom_domains" {
    for_each = var.custom_domains
    content {
      fqdn                 = custom_domains.value.fqdn
      certificate_id       = custom_domains.value.certificate_id
    }
  }
  # canary {
  #   variables              = var.canary_variables
  #   weight                 = var.canary_weight}
}

resource "yandex_dns_recordset" "api_gateway" {
  for_each                 = { for domain in var.custom_domains : domain.fqdn => domain }

  zone_id                  = var.dns_zone_id
  name                     = "${each.key}."
  type                     = "CNAME"
  ttl                      = 60
  data                     = [yandex_api_gateway.this.domain]
}