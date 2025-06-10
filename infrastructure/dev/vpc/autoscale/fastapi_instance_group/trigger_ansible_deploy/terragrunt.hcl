terraform {
  source = "${get_repo_root()}/modules//autoscale_group_trigger_ansible_deploy/"
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "instance_group" {
  config_path                             = "../../fastapi_instance_group"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "providers", "terragrunt-info", "show"]
  mock_outputs = {
    instance_group_id = "instance-group-id-fake"
  }
}


locals {
  env       = include.root.locals.env_vars.locals.env
  work_dir  = include.root.locals.work_dir
  # folder_id = include.root.locals.env_vars.locals.folder_id
}

inputs = {  
  # GENERAL
  env                           = local.env
  # folder_id                     = local.folder_id
  instance_group_id             = dependency.instance_group_guaranteed.outputs.instance_group_id
  service_account_id            = "ajef2vu3kdm3ch6pksea"                                   # for now
  bucket_name                   = "project-dildakot--yc-backend--k2bz6lv7"
  object_name                   = "${path_relative_to_include()}/send-metric-function.zip"
  sa_key_path                   = "${local.work_dir}/secrets/ops/yc_admin_sa_key.json"     # for now
  
  # RESOURCES
  gitlab_trigger_token          = "glptt-b67dd43e15b10fc5c60af464b35cdc87916d9d1c"
  gitlab_project_id             = "70190498"
  gitlab_branch                 = "test"
}