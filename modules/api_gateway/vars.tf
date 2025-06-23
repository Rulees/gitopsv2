# DEFAULT
variable "project_prefix" {
  description = "Prefix used for naming resources (e.g., project name)"
  type        = string
}

variable "env" {
  description = "Environment for the api_gateway (e.g., dev, prod)"
  type        = string
}

# GENERAL
variable "service_account_id" {
  description = "Service account ID used by the api_gateway."
  type        = string
  default     = null
}

variable "container_id" {
  description = "ID of the serverless container to invoke"
  type        = string
}

variable "network_id" {
  description = "Network(vpc) id"
  type        = string
}

variable "dns_zone_id" {
  description = "DNS zone to use for custom domains"
  type        = string
}

# RESOURCES
variable "use_container_mode" {
  description = "Use serverless container (true). It means to use such vars as sa_id and container_id"
  type        = bool
  default     = true
}

variable "api_gateway_name" {
  description = "The short name of the gatewayapi. Example: apigateway. Typically generated dynamically using project_prefix, env"
  type        = string
  default     = "api_gateway"
}

variable "execution_timeout" {
  description = "execution timeout for each request (e.g. 15s, 60s). New requst set new <120> seconds"
  type        = string
  default     = "120s"
}

variable "custom_domains" {
  description = "List of domains + certificate IDs to attach"
  type = list(object({
    fqdn           = string
    certificate_id = string
  }))
  default = []
}

# IF CANARY and folder on level of sa_ and backend_
# variable "canary_variables" {
#   description = "A list of values for variables in gateway specification of canary release"
#   type        = map(string)
#   default     = {}
# }

# variable "canary_weight" {
#   description = "Percentage of requests, which will be processed by canary release"
#   type        = number
#   default     = 100
# }