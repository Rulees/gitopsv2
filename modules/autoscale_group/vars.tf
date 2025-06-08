##
# DEFAULTS
##

variable "project_prefix" {
  description = "Prefix for naming"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "instance_group_name" {
  description = "Name of the instance group"
  type        = string
}

variable "labels" {
  description = "Resource labels"
  type        = map(string)
  default     = {}
}

variable "service_account_id" {
  description = "Service Account ID"
  type        = string
}


##
# SCALE
##

variable "scheduling_policy_preemptible" {
  description = "Whether instances are preemptible"
  type        = bool
}

variable "zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "size" {
  description = "Fixed size of instance group"
  type        = number
  default     = null
}


# SCALE: AUTOSCALE
variable "min_zone_size" {
  description = "Minimum VMs per zone"
  type        = number
  default     = null
}
variable "initial_size" {
  description = "Initial size of the instance group"
  type        = number
  default     = null
}
variable "max_size" {
  description = "Maximum size of the instance group"
  type        = number
  default     = 10
}
variable "measurement_duration" {
  description = "Duration in seconds for measuring CPU"
  type        = number
  default     = null
}
variable "stabilization_duration" {
  description = "Time in seconds before scale-down decision"
  type        = number
  default     = null
}
variable "warmup_duration" {
  description = "Warmup period before CPU monitoring"
  type        = number
  default     = null
}
variable "cpu_utilization_target" {
  description = "CPU load target for autoscaling"
  type        = number
  default     = null
}

# DEPLOY POLICY
variable "max_expansion" {
  description = "Max temporary VM creation during update"
  type        = number
}
variable "max_creating" {
  description = "Max VMs created in scale-up"
  type        = number
}
variable "max_unavailable" {
  description = "Max unavailable instances during update"
  type        = number
}
variable "max_deleting" {
  description = "Max VMs deleted in scale-down"
  type        = number
}
variable "startup_duration" {
  description = "Startup time in seconds"
  type        = number
}


##
# INSTANCE TEMPLATE
##

variable "platform_id" {
  description = "Platform ID, e.g. standard-v3"
  type        = string
}

variable "cores" {
  description = "Number of CPU cores"
  type        = number
}

variable "core_fraction" {
  description = "CPU performance percent"
  type        = number
}

variable "memory" {
  description = "RAM size (GB)"
  type        = number
}

variable "boot_disk" {
  description = "Boot disk parameters"
  type = object({
    image_id = string
    type     = string
    size     = number
  })
}


##
# NETWORK
##

variable "network_interfaces" {
  description = "Network interfaces"
  type = list(object({
    subnet_ids          = optional(list(string))
    nat                 = bool
    security_group_ids  = list(string)
  }))
}

variable "subnet_names" {
  description = "Names of subnets to attach by order"
  type        = list(string)
}

##
# SSH
##

variable "ssh" {
  description = "SSH access config"
  type = object({
    ssh_user = string
    ssh_key  = string
  })
}


##
# HEALTH CHECK
##

variable "max_checking_health_duration" {
  description = "Max time to wait for healthy VM"
  type        = number
}

variable "health_check" {
  description = "Health check settings"
  type = object({
    interval            = number
    timeout             = number
    healthy_threshold   = number
    unhealthy_threshold = number
    http_options = optional(object({
      port = number
      path = string
    }))
    tcp_options = optional(object({
      port = number
    }))
  })
}
