terraform {
  source = "${get_repo_root()}/modules/dbs//postgresql/"
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


locals {
  env                = include.root.locals.env_vars.locals.env
  zone               = include.root.locals.env_vars.locals.zone
  work_dir           = include.root.locals.work_dir
  labels             = merge({env = local.env}, {app = include.root.locals.app}, {service = include.root.locals.service}, length(include.root.locals.subservice) > 0 ? { subservice = include.root.locals.subservice } : {})
  secrets            = yamldecode(file("${local.work_dir}/secrets/dev/atlas/postgresql/.yml")) 
}

inputs = {
  ##
  # GENERAL
  ##

  env                  = local.env         
  zone                 = local.zone
  labels               = local.labels
  network_id           = dependency.network.outputs.vpc_id
  subnet_id            = dependency.network.outputs.subnet_id

  ##
  # CLUSTER
  ##

  cluster_name         = "postgresql_cluster"
  cluster_environment  = "PRESTABLE"
  db_version           = 17
  disk_size            = 10
  disk_type_id         = "network-ssd"
  resource_preset_id   = "s3-c2-m8"
  assign_public_ip     = true
  
  ##
  # DATABASE
  ##

  db_login             = local.secrets.db_login
  db_password          = local.secrets.db_password
  db_name              = "postgresql"
}