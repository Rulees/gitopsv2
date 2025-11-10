terraform {
  source = "${get_repo_root()}/modules//serverless/"
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

dependency "sa_serverless_deploy" {
  config_path                             = "../../../../sa_/serverless_deploy"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "providers", "terragrunt-info", "show"]
  mock_outputs  = {
    sa_id = "sa-id-fake"
  }
}

dependency "registry" { 
  config_path                             = "../../../registry/"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "providers", "terragrunt-info", "show"]
  mock_outputs  = {
    registry_id = "registry-id-fake"
  }
}

locals {
  env             = include.root.locals.env_vars.locals.env
  zone            = include.root.locals.env_vars.locals.zone
  work_dir        = include.root.locals.work_dir
  app             = include.root.locals.app
  service         = include.root.locals.service
  labels          = merge({env = local.env}, {app = include.root.locals.app}, {service = include.root.locals.service}, length(include.root.locals.subservice) > 0 ? { subservice = include.root.locals.subservice } : {})
}


inputs = {  
  # GENERAL
  env                           = local.env
  zone                          = local.zone
  labels                        = local.labels
  network_id                    = dependency.network.outputs.vpc_id
  service_account_id            = dependency.sa_serverless_deploy.outputs.sa_id


  # RESOURCES
  name                          = "website-serverless"
  runtime_type                  = "http"
  image_url                     = "cr.yandex/${dependency.registry.outputs.registry_id}/${local.app}-${local.service}:latest"
  cores                         = 1
  core_fraction                 = 100
  memory                        = 1024 #MB
  concurrency                   = 16
  min_instances                 = 1
  execution_timeout             = "15s"
  public                        = true
}
