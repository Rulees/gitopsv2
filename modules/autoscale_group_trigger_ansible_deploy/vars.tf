# DEFAULT
variable "project_prefix" {
  description = "Prefix used for naming resources (e.g., project name)"
  type        = string
}

variable "folder_id" {
  description = "Folder ID for the Cloud Function"
  type        = string
}

# GENERAL
variable "network_id" {
  description = "Network (VPC) ID"
  type        = string
}

variable "trigger_name" {
  description = "Name of the function trigger"
  type        = string
  default     = "trigger-ansible-on-autoscale"
}

variable "service_account_id" {
  description = "Service account with permissions for compute and GitLab trigger"
  type        = string
  default     = null
}


# FUNCTION
variable "function_name" {
  description = "Name of the Cloud Function"
  type        = string
  default     = "trigger-gitlab-ansible"
}

variable "sa_key_path" {
  description = "Path to service account JSON file used inside function"
  type        = string
}

variable "bucket_name" {
  description = "Object Storage bucket to store function zip"
  type        = string
}

variable "object_name" {
  description = "The name of the object (ZIP file) to be uploaded to the bucket"
  type        = string
}

variable "cron_expression" {
  description = "Cron expression to trigger the function periodically(every minute)"
  type        = string
  default     = "* * * * *"
}

# GITLAB-SPECIFIC
variable "gitlab_trigger_token" {
  description = "GitLab pipeline trigger token"
  type        = string
}

variable "gitlab_project_id" {
  description = "GitLab project ID (optional, for context)"
  type        = string
  default     = ""
}

variable "gitlab_branch" {
  description = "GitLab ref (branch) to trigger, where gitlab stage(ansible deploy to fastapi) is located"
  type        = string
  default     = "main"
}

variable "env" {
  description = "Environment for the function (e.g., dev, prod)"
  type        = string
}

variable "app" {
  description = "Application name (e.g., fastapi-backend)"
  type        = string
}

variable "service" {
  description = "Service name (e.g., api, web)"
  type        = string
}