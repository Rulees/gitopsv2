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
#   env                = include.root.locals.env_vars.locals.env
  zone               = include.root.locals.env_vars.locals.zone
  labels             = merge({env = local.env}, {app = include.root.locals.app}, {service = include.root.locals.service}, length(include.root.locals.subservice) > 0 ? { subservice = include.root.locals.subservice } : {})
}

inputs = {
  zone            = local.zone
  labels          = local.labels
}