terraform {
  source = "${get_repo_root()}/modules//autoscale-group/"
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "network" {
  config_path                             = "../../../network/"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "providers", "terragrunt-info", "show"]
  mock_outputs = {
    vpc_id     = "network-id-fake"
    subnet_id  = "subnet-id-fake"
  }
}

dependency "sg" {
  config_path                             = "../../../sg/"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "providers", "terragrunt-info", "show"]
  mock_outputs = {
    sg_id = "sg-id-fake"
  }
}

dependency "consul_server" {
  config_path = "../../../consul_server/"
}

dependency "metric_cpu_average" {
  config_path                             = "./metric_cpu_average/"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "providers", "terragrunt-info", "show", "apply"]
  mock_outputs = {
    instance_group_id = "instance-group-id-fake"
  }
}

locals {
  env            = include.root.locals.env_vars.locals.env
  zone           = include.root.locals.env_vars.locals.zone
  work_dir       = include.root.locals.work_dir
  # Labels
  env_labels     = include.root.locals.env_vars.locals.env_labels
  app_labels     = {app = "${basename(dirname(get_terragrunt_dir()))}"}
  service_labels = {service = "${basename(get_terragrunt_dir())}"}
  labels         = merge(local.env_labels, local.app_labels, local.service_labels)
}

inputs = {
  ##
  # GENERAL
  ##

  env                           = local.env
  zone                          = local.zone
  labels                        = local.labels
  service_account_id            = "ajef2vu3kdm3ch6pksea" # only for now



  ##
  # SCALE  [auto/fixed]
  ##
  
      ##
      # FIXED
      ##



      ##
      # AUTO
      ##



  

  # ---------DEFAULT_VALUES-----------
# autoscale_policy = {  
      min_zone_size             = 1     # Minimum vm's per zone (if zone is used!!). Doesn't force all zones to be used.
    # max_size                  = 10
    # initial_size              = 3     # started value and minimum
    # cpu_utilization_target    = 0.6   # 40%=availability, 70%=cost. The percentage is low, cause of necessity to scale beforehand
      measurement_duration      = 60    # Time to measure cpu_average
      stabilization_duration    = 60    # Time to wait after "measurement_duration" for making decision to scale-down amount of VM's (only down-auto-scale)
      warmup_duration           = 30    # Time to wait after "startup_duraion" before start cpu-monitoring                           (only scale, not update)


# deploy_policy = {
      max_expansion             = 2     # How many vm's can be *created* at once during *update* to replace old ones, before removing old ones.
      max_creating              = 5     # How many vm's can be *created* at once during *scale* , if highload
      max_unavailable           = 0     # How many vm's can be *offline* at once during *update* (stopped or deleted), before new ones are ready
      max_deleting              = 2     # How many vm's can be *removed* at once
      startup_duration          = 120   # Time to wait after *update(max_expansion) / scale(max_creating)*, before considering a new VM "ready"(cause of ansible-provision)




  # ------------- LOW_COST -----------------
  scheduling_policy_preemptible = true
  zones                         = ["a"]
  #autoscale_policy = {
      initial_size              = 1
      cpu_utilization_target    = 0.7



  # --------- HIGH_AVAILABILITY ------------
  scheduling_policy_preemptible = false
  zones                         = ["a", "b", "c"]
  #autoscale_policy = {
      initial_size              = 3
      cpu_utilization_target    = 0.4



  # -------- LOW_COST + HIGHLOAD -----------
    # GROUP 1: GUARANTEED INSTANCES
  scheduling_policy_preemptible = false
  zones                         = ["a", "b", "c"]
  #autoscale_policy = {
      initial_size              = 1    # If initial_size(x):  x=1, x=2, x=3..
      max_size                  = 2    # Then   max_size(y):  y=2, y=4, y=6...
      cpu_utilization_target    = 0.4
     
  

    # GROUP 2: PREEMPTIBLE INSTANCES
  scheduling_policy_preemptible = true
  zones                         = ["a", "b", "c"]
  #autoscale_policy = {
      max_size                  = 10
      initial_size              = 0    # COLD START. So we use custom metric(cpu_average) from GROUP 1
      cpu_utilization_target    = 0.7

  



























  ##
  # INSTANCE
  ##
  
  name                          = "vm"
  platform_id                   = "standard-v3"
  cores                         = 2
  core_fraction                 = 20   #=100 is preferrable for real case
  memory                        = 4
  boot_disk = {
    type                        = "network-ssd"
    image_id                    = "fd8kc2n656prni2cimp5" # container-optimized-image
    size                        = 15
  }

  # NETWORK
  network_interfaces = [{
    subnet_id                   = dependency.network.outputs.subnet_id
    security_group_ids          = [dependency.sg.outputs.sg_id]
    
    # CHOICE (Uncomment one):   #1) Dynamic NAT  #2) Use static IP  #3) Enable DDoS-protected static IP
    nat                         = true
    # nat_ip_address              = "158.160.39.80"
  }]
  # static_ip_ddos_protection     = true

  # SSH
  ssh = {
    ssh_user                    = "melnikov"
    ssh_key                     = file("${local.work_dir}/secrets/admin/yc_ssh_key.pub")
  }












##
# SCALE - AUTO
##

# CREATE//  *max_creating*  >  startup  >  warmup  >  measurement(high)     >  ***max_creating***                             >  startup  >  *health_check(true)*  
# DELETE//                                            measurement(low)      >  stabilization(low)     >  ***max_deleting*** 
# UPDATE//                                               ...                >  UPDATE                 >  ***max_expansion***  >  startup  >  *health_check(true)*   >  ***max_deleting***
# HEALTH_CHECK(failure)//                                                                                                        startup  >  *health_check(false)* for max_checking_health_duration  >  UPDATE
# NOTHING//                                           measurement(low)      >  stabilization(medium)  >  ***...***

# ##
# # DESCRIPTION OF PARAMETERS
# ##

# scheduling_policy_preemptible   = true
# autoscale_policy = {
#     min_zone_size               = 1
#     max_size                    = 10
#     initial_size                = 3    # 1) MAX(vm in every zone):  initial_size >= zones * min_zone_size
#                                      # 2) MIN(one zone):          initial_size >= min_zone_size

#     cpu_utilization_target      = 0.6  # 40%=availability, 70%=cost. The percentage is low, cause of necessity to scale beforehand
#     measurement_duration        = 60   # Time to measure cpu_average

#     stabilization_duration      = 60   # Time to wait after "measurement_duration" for making decision to scale-down amount of VM's (only down-auto-scale)
#     warmup_duration             = 30}  # Time to wait after "startup_duraion" before start cpu-monitoring                           (only scale, not update)

# deploy_policy = {
#     max_expansion               = 2    # How many vm's can be *created* at once during *update* to replace old ones, before removing old ones.
#     max_creating                = 5    # How many vm's can be *created* at once during *scale* , if highload
#     max_unavailable             = 1    # How many vm's can be *offline* at once during *update* (stopped or deleted)
#     max_deleting                = 1    # How many vm's can be *removed* at once
#     startup_duration            = 120} # Time to wait after *update(max_expansion) / scale(max_creating)*, before considering a new VM "ready"(cause of ansible-provision)
# }

# max_checking_health_duration    = 
#   health_check = {
#       interval                  = 10
#       timeout                   = 5
#       healthy_threshold         = 2
#       unhealthy_threshold       = 3
#     http_options = {
#       path = "/healthz"
#       port = 80
#     }
#   }
}