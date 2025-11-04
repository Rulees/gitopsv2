# terraform {
#   source = "${get_repo_root()}/modules//autoscale_group_trigger_ansible_deploy/"
# }

# include "root" {
#   path   = find_in_parent_folders("root.hcl")
#   expose = true
# }

# dependency "network" {
#   config_path                             = "../../../../network/"
#   mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "providers", "terragrunt-info", "show"]
#   mock_outputs = {
#     vpc_id     = "network-id-fake"
#     subnet_id  = "subnet-id-fake"
#   }
# }

# dependency "instance_group" {
#   config_path                             = "../../service_color"
#   mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "providers", "terragrunt-info", "show"]
#   mock_outputs = {
#     instance_group_id = "instance-group-id-fake"
#   }
# }


# locals {
#   env        = include.root.locals.env_vars.locals.env
#   work_dir   = include.root.locals.work_dir
#   app        = include.root.locals.app
#   service    = include.root.locals.service
#   subservice = include.root.locals.subservice
#   labels     = merge({env = local.env}, {app = include.root.locals.app}, {service = include.root.locals.service}, length(include.root.locals.subservice) > 0 ? { subservice = include.root.locals.subservice } : {})
# }

# inputs = {  
#   # GENERAL
#   env                           = local.env
#   app                           = local.app
#   service                       = local.service
#   subservice                    = local.subservice
#   labels                        = local.labels
#   instance_group_id             = dependency.instance_group.outputs.instance_group_id
#   network_id                    = dependency.network.outputs.vpc_id
#   service_account_id            = "ajeo95lo98ru1rkd8fm6"                                     # for now
#   bucket_name                   = "project-dildakot--yc-backend--dmvlelmn"
#   object_name                   = "${path_relative_to_include()}/send-metric-function.zip"
#   sa_key_path                   = "${local.work_dir}/secrets/admin/yc_admin_sa_key.json"     # for now
  
#   # RESOURCES
#   gitlab_trigger_token          = "glptt-b67dd43e15b10fc5c60af464b35cdc87916d9d1c"
#   gitlab_project_id             = "70190498"
#   gitlab_branch                 = "test"
# }
