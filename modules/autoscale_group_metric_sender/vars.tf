# DEFAULT
variable "project_prefix" {
  description = "Prefix used for naming resources (e.g., project name)"
  type        = string
}

variable "env" {
  description = "Environment for the container (e.g., dev, prod)"
  type        = string
}

variable "folder_id" {
  description = "Folder ID for the Cloud Function and monitoring metric"
  type        = string
}

# GENERAL
variable "network_id" {
  description = "Network(vpc) id"
  type        = string
}

variable "trigger_name" {
  description = "Name of the function trigger"
  type        = string
  default     = "send-cpu_average_metric-on-timer"
}

variable "service_account_id" {
  description = "Service account with permission to restart container"
  type        = string
  default     = null
}


# FUNCTION
variable "function_name" {
  description = "Name of the Cloud Function"
  type        = string
  default     = "push-custom-metric"
}

variable "sa_key_path" {
  description = "Path to service account JSON file used inside function"
  type        = string
}

variable "bucket_name" {
  description = "Name of the Object Storage bucket to store function zip"
  type        = string
}

variable "object_name" {
  description = "The name of the object (ZIP file) to be uploaded to the bucket"
  type        = string
}

variable "cron_expression" {
  description = "Cron expression to trigger the function periodically(every minute)"
  type        = string
  default     = "* * * * ? *"
}

variable "metric_name" {
  description = "Name of the custom metric to push"
  type        = string
  default     = "custom.cpu.average"
}

variable "instance_group_id" {
  description = "ID of the guaranteed instance group to fetch CPU usage from"
  type        = string
}