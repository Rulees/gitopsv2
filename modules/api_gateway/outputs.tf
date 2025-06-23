output "api_gateway_id" {
  description          = "ID of APIGateway"
  value                = yandex_api_gateway.this.id
}

output "custom_domains" {
  description          = "List of domains for APIGateway"
  value                = yandex_api_gateway.this.custom_domains
}