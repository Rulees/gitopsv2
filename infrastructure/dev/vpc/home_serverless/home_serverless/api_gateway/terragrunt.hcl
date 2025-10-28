terraform {
  source = "${get_repo_root()}/modules//api_gateway/"
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "network" {
  config_path                             = "../../../../network/"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "providers", "terragrunt-info", "show"]
  mock_outputs = {
    vpc_id     = "network-id-fake"
    subnet_id  = "subnet-id-fake"
  }
}

dependency "sa_api_gateway_editor" {
  config_path                             = "../../../../../sa_/api_gateway_editor"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "providers", "terragrunt-info", "show"]
  mock_outputs  = {
    sa_id = "sa-id-fake"
  }
}

dependency "serverless_container" {
  config_path = "../../home_serverless"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "providers", "terragrunt-info", "show"]
  mock_outputs   = {
    container_id = "container-id-fake"
  }
}


locals {
  env                = include.root.locals.env_vars.locals.env
  zone               = include.root.locals.env_vars.locals.zone
}


inputs = {  
  # GENERAL
  env                = local.env
  zone               = local.zone
  network_id         = dependency.network.outputs.vpc_id
  service_account_id = dependency.sa_api_gateway_editor.outputs.sa_id
  container_id       = dependency.serverless_container.outputs.container_id
  dns_zone_id        = "dns12p5f0ll3325ftjlo"

  # RESOURCES
  api_gateway_name   = "api-gateway"
  execution_timeout  = "300"
  custom_domains = [{
      fqdn           = "lotsmen.ru"
      certificate_id = "fpqtvofbcurh6pj54pcq"},
    # {
    #   fqdn           = "gtgt.arkselen.ru"
    #   certificate_id = "fpq82j0a9t28aealltc8"
    # }
]}
