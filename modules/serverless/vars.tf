# DEFAULT
variable "project_prefix" {
  description = "Prefix used for naming resources (e.g., project name)"
  type        = string
}

variable "env" {
  description = "Environment for the container (e.g., dev, prod)"
  type        = string
}


# GENERAL
variable "runtime_type" {
  description = "Runtime environment for the container, e.g. 'http' or 'task'"
  type = string
  default = "http"
}

variable "labels" {
  description = "Key-value map of labels assigned to the container."
  type        = map(string)
  default     = {}
}

variable "service_account_id" {
  description = "Service account ID used by the container."
  type        = string
  default     = null
}

variable "network_id" {
  description = "Network(vpc) id"
  type        = string
}


# RESOURCES
variable "container_name" {
  description = "The short name of the serverless container. Example: container. Typically generated dynamically using project_prefix, env"
  type        = string
  default     = "container"
}

variable "image_url" {
  description = "Image URL for the container, including tag (e.g. latest)."
  type        = string
  default     = ""
}

variable "cores" {
  description = "Number of CPU cores allocated to the container."
  type        = number
  default     = 1
}

variable "core_fraction" {
  description = "CPU core fraction (in percent) for burstable CPU."
  type        = number
  default     = 100
}

variable "memory" {
  description = "Amount of memory (in MB) allocated to the container."
  type        = number
  default     = 1024
}

variable "concurrency" {
  description = "Maximum number of concurrent requests the container can handle. New container will be create if more than 500.  Default quote for http = 16"
  type        = number
  default     = 16
}

variable "min_instances" {
  description = "Minimum number of container instances to keep running."
  type        = number
  default     = 0
}

variable "execution_timeout" {
  description = "execution timeout for each request (e.g. 15s, 60s). New requst set new <120> seconds"
  type        = string
  default     = "120s"
}

variable "public" {
  description = "Whether to make the container publicly invokable"
  type        = bool
  default     = false
}