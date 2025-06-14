data "yandex_vpc_subnet" "by_name" {
  for_each = toset(var.subnet_names)
  name     = each.value
}

locals {
  name = "${var.project_prefix}--${var.instance_group_name}--${var.env}"
}

resource "yandex_compute_instance_group" "this" {
  
  ##
  # GENERAL
  ##

  name                         = local.name
  description                  = "${var.project_prefix} instance-group for ${var.env} environment"
  service_account_id           = var.service_account_id


  ##
  # SCALE  [auto/fixed]
  ##

  allocation_policy {zones     = [for z in var.zones : "ru-central1-${z}"]}
  
  deploy_policy {
    max_expansion              = var.max_expansion
    max_creating               = var.max_creating
    max_unavailable            = var.max_unavailable
    max_deleting               = var.max_deleting
    startup_duration           = var.startup_duration
  }

  scale_policy {    
    
    # FIXED
    dynamic "fixed_scale" {
      for_each                 = var.size != null && var.initial_size == null ? [1] : []

      content {
        size                   = var.size
      }
    }

    # AUTO
    dynamic "auto_scale" {
      for_each                 = var.initial_size != null && var.size == null ? [1] : []

      content {
        min_zone_size          = var.min_zone_size
        initial_size           = var.initial_size
        max_size               = var.max_size
        measurement_duration   = var.measurement_duration
        stabilization_duration = var.stabilization_duration
        warmup_duration        = var.warmup_duration
        cpu_utilization_target = var.cpu_utilization_target
      }
    }
  }

  ##
  # HEALTH_CHECK
  ##

  max_checking_health_duration = var.max_checking_health_duration
  health_check {
    interval                   = var.health_check.interval
    timeout                    = var.health_check.timeout
    healthy_threshold          = var.health_check.healthy_threshold
    unhealthy_threshold        = var.health_check.unhealthy_threshold

    dynamic "http_options" {
      for_each                 = var.health_check.http_options != null ? [1] : []

      content {
        port                   = var.health_check.http_options.port
        path                   = var.health_check.http_options.path
      }
    }

    dynamic "tcp_options" {
      for_each                 = var.health_check.tcp_options != null ? [1] : []

      content {
        port                   = var.health_check.tcp_options.port
      }
    }
  }

  ##
  # INSTANCE
  ##
  
  instance_template {
    labels                     = var.labels
    platform_id                = var.platform_id
    scheduling_policy {
      preemptible              = var.scheduling_policy_preemptible
    }


    resources {
      cores                    = var.cores
      memory                   = var.memory
      core_fraction            = var.core_fraction
    }

    boot_disk {    
      initialize_params {
        image_id               = var.boot_disk.image_id
        type                   = var.boot_disk.type
        size                   = var.boot_disk.size
      }
    }

    # NETWORK
    network_interface {
      subnet_ids               = [for z in var.zones : { for k, v in data.yandex_vpc_subnet.by_name : v.zone => v.id }["ru-central1-${z}"]]
      nat                      = var.network_interfaces[0].nat
      security_group_ids       = var.network_interfaces[0].security_group_ids
    }

    # SSH
    metadata = {
      user-data = templatefile("cloud-init.yml", {
        ssh_user = var.ssh.ssh_user
        ssh_key = var.ssh.ssh_key
      })
    }
  }
}
