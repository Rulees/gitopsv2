terraform {
  source = "${get_repo_root()}/modules//autoscale_group/"
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "network" {
  config_path                             = "../../../network/"
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

# dependency "metric_cpu_average" {
#   config_path                             = "./metric_sender/"
#   mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "providers", "terragrunt-info", "show", "apply"]
#   mock_outputs = {
#     instance_group_id = "instance-group-id-fake"
#   }
# }

locals {
  env                                       = include.root.locals.env_vars.locals.env
  zone                                      = include.root.locals.env_vars.locals.zone
  work_dir                                  = include.root.locals.work_dir
  # Labels
  env_labels                                = include.root.locals.env_vars.locals.env_labels
  app_labels                                = {app = "${basename(dirname(get_terragrunt_dir()))}"}
  service_labels                            = {service = "${basename(get_terragrunt_dir())}"}
  deployment_trigger                        = {deployed = false} # trigger to avoid reapplying
  labels                                    = merge(local.env_labels, local.app_labels, local.service_labels, local.deployment_trigger)
}

inputs = {
  ##
  # GENERAL
  ##
  
  env                          = local.env
  zone                         = local.zone
  labels                       = local.labels
  service_account_id           = "ajef2vu3kdm3ch6pksea" # only for now

  ##
  # HEALTH_CHECK
  ##

  max_checking_health_duration = 120  # = startup_duration, if ansible else
  health_check = {
    interval                   = 10
    timeout                    = 5
    healthy_threshold          = 2
    unhealthy_threshold        = 3

    # HTTP/TCP(only one)
    # http_options = {
        # path = "/health"
        # port = 8000 # check for ansible-provision
    # }

    tcp_options = {
        port = 22
    }    
  }

  


  ##
  # SCALE  [auto/fixed]
  ##

                  # ---------DEFAULT_VALUES_ALL-----------
                  instance_group_name                          = "instance-group" # comment if use case_3
                  # deploy_policy = {
                                        max_expansion          = 2     # How many vm's can be *created* at once during *update* to replace old ones, before removing old ones.
                                        max_creating           = 5     # How many vm's can be *created* at once during *scale* , if highload
                                        max_unavailable        = 0     # How many vm's can be *offline* at once during *update* (stopped or deleted), before new ones are ready
                                        max_deleting           = 2     # How many vm's can be *removed* at once
                                        startup_duration       = 120   # Time to wait after *update(max_expansion) / scale(max_creating)*, before considering a new VM "ready"(cause of ansible-provision)


                  # ---------DEFAULT_VALUES_AUTO-----------
                  # autoscale_policy = {  
                                        min_zone_size          = 3     # Minimum vm's per zone (if zone is used!!)
                                      # max_size               = 10
                                      # initial_size           = 3     # started value and minimum. (1) must be >= zone_count * min_zone_size (3)
                                      # cpu_utilization_target = 60.0  # 40%=availability, 70%=cost. The percentage is low, cause of necessity to scale beforehand
                                        measurement_duration   = 60    # Time to measure cpu_average
                                        stabilization_duration = 90    # Time to wait after "measurement_duration" for making decision to scale-down amount of VM's (only down-auto-scale)
                                        warmup_duration        = 30    # Time to wait after "startup_duraion" before start cpu-monitoring                           (only scale, not update)


                  


  # FIXED_SCALE_CONFIG
  # scheduling_policy_preemptible = false
  # zones                         = ["a", "b", "d"]
  # size                          = 3


  # AUTO_SCALE_CONFIG
  # ------------- LOW_COST (#1) -----------------
  scheduling_policy_preemptible = true
  # zones                         = ["a"]
  zones                         = ["a", "b"]
  # zones                         = ["a", "b", "d"]
  initial_size                  = 2
  cpu_utilization_target        = 70.0



  # # --------- HIGH_AVAILABILITY (#2) ------------
  # scheduling_policy_preemptible = false
  # zones                         = ["a", "b", "d"]
  # initial_size                  = 3
  # cpu_utilization_target        = 40.0



  # # -------- LOW_COST + HIGHLOAD (#3) -----------
  #   # GROUP 1: GUARANTEED INSTANCES
  # guarant_instance_group_name   = "guaranteed-instance-group"
  # scheduling_policy_preemptible = false
  # zones                         = ["a", "b", "d"]
  # #autoscale_policy = {
  #     initial_size              = 1    # If initial_size(x):  x=1, x=2, x=3..          (1) must be >= zone_count * min_zone_size (3)
  #     max_size                  = 2    # Then   max_size(y):  y=2, y=4, y=6...
  #     cpu_utilization_target    = 40.0
     
  

  #   # GROUP 2: PREEMPTIBLE INSTANCES
  # preempt_instance_group_name   = "preemptible-instance-group"
  # scheduling_policy_preemptible = true
  # zones                         = ["d", "b", "a"]
  # #autoscale_policy = {
  #     initial_size              = 1    # 0=COLD START. So we use GROUP 1 to get custom metric(cpu_average)
  #     max_size                  = 10
  #     cpu_utilization_target    = 70.0

  


  ##
  # INSTANCE
  ##
  
  name                          = "vm"
  platform_id                   = "standard-v3"
  cores                         = 2
  core_fraction                 = 100   # cant't be less
  memory                        = 4
  boot_disk = {
    type                        = "network-ssd"
    image_id                    = "fd8kc2n656prni2cimp5" # container-optimized-image
    size                        = 15
  }

  # NETWORK
  subnet_names                  = ["yc-a", "yc-b", "yc-d"]
  network_interfaces = [{
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
}



# CREATE//  *max_creating*  >  startup  >  warmup  >  measurement(high)     >  ***max_creating***                             >  startup  >  *health_check(true)*  
# DELETE//                                            measurement(low)      >  stabilization(low)     >  ***max_deleting*** 
# UPDATE//                                               ...                >  UPDATE                 >  ***max_expansion***  >  startup  >  *health_check(true)*   >  ***max_deleting***
# HEALTH_CHECK(failure)//                                                                                                        startup  >  *health_check(false)* for max_checking_health_duration  >  UPDATE
# NOTHING//                                           measurement(low)      >  stabilization(medium)  >  ***...***
