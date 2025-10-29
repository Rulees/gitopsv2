terraform {
  source = "${get_repo_root()}/modules//autoscale_group_metric_sender/"
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}


dependency "sa_metric_sender" {
  config_path                             = "../../../../../sa_/metric_sender"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "providers", "terragrunt-info", "show"]
  mock_outputs  = {
    sa_id = "sa-id-fake"
  }
}

dependency "instance_group_guaranteed" {
  config_path                             = "../../fastapi_instance_group"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "providers", "terragrunt-info", "show", "apply"]
  mock_outputs = {
    instance_group_id = "instance-group-id-fake"
  }
}


locals {
  env       = include.root.locals.env_vars.locals.env
  work_dir  = include.root.locals.work_dir
}

inputs = {  
  env                           = local.env
  instance_group_id             = dependency.instance_group_guaranteed.outputs.instance_group_id
  service_account_id            = dependency.sa_metric_sender.outputs.sa_id
  bucket_name                   = "project-dildakot--yc-backend--dmvlelmn"
  object_name                   = "${path_relative_to_include()}/send-metric-function.zip"
  sa_key_path                   = "${local.work_dir}/secrets/ops/yc_metric_send_sa_key.json"
}
