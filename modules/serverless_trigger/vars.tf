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
variable "network_id" {
  description = "Network(vpc) id"
  type        = string
}

variable "trigger_name" {
  description = "Name of the function trigger"
  type        = string
  default     = "restart-container-on-image-push"
}

variable "registry_id" {
  description = "Yandex Container Registry ID"
  type        = string
}

variable "container_id" {
  description = "ID of the serverless container to restart"
  type        = string
}

variable "service_account_id" {
  description = "Service account with permission to restart container"
  type        = string
  default     = null
}

variable "image_name" {
  description = "Name of the image to watch for (e.g., 'website')"
  type        = string
}

variable "image_tag" {
  description = "Tag of the image to trigger on (e.g., 'latest')"
  type        = string
  default     = "latest"
}

variable "create_image_tag" {
  description = "Enable/Disable trigger on image tag creation"
  type        = bool
  default     = true
}

variable "batch_cutoff" {
  description = "Time in seconds for trigger to stop listening and start peforming. If 5 seconds, then gets image, wait 5 seconds for a case of new image, then perform"
  type        = string
  default     = "1"
}

variable "batch_size" {
  description = "Number of messages to get before trigger. Example: 5, then wait 5 images"
  type        = string
  default     = "1"
}

# FUNCTION
variable "function_name" {
  description = "Name of the Cloud Function"
  type        = string
  default     = "restart-serverless-container"
}

variable "image_url" {
  description = "Full Docker image URL to redeploy the container (used by Cloud Function)"
  type        = string
}

variable "sa_key_path" {
  description = "Path to service account JSON file used inside function"
  type        = string
}

variable "bucket_name" {
  description = "Name of the Object Storage bucket to store function zip"
  type        = string
}

variable "container_resources" {
  description = "All Serverless-container resource are used to send grpc-request inside yandex_function(python-sdk) to deploy new revision of container on every image push with tag latest. Image has to be updated to update"
  type        = any
}

variable "object_name" {
  description = "The name of the object (ZIP file) to be uploaded to the bucket"
  type        = string
}


