terraform {
  source = "${get_repo_root()}/modules//serverless_trigger/"
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

dependency "sa_serverless_deploy" {
  config_path                             = "../../../../../sa_/serverless_deploy"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "providers", "terragrunt-info", "show"]
  mock_outputs  = {
    sa_id = "sa-id-fake"
  }
}

dependency "registry" { 
  config_path                             = "../../../../registry/"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "providers", "terragrunt-info", "show"]
  mock_outputs  = {
    registry_id = "registry-id-fake"
  }
}

dependency "serverless_container" {
  config_path = "../../website_serverless"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "providers", "terragrunt-info", "show"]
  mock_outputs   = {
    container_id        = "container-id-fake"
    container_resources = "resources-fake"
    image_url           = "mock-registry.io/registry-id/image:latest"
  }
}

locals {
  env      = include.root.locals.env_vars.locals.env
  work_dir = include.root.locals.work_dir
  app      = include.root.locals.app
  service  = include.root.locals.service
}

inputs = {  
  # GENERAL
  env                           = local.env
  network_id                    = dependency.network.outputs.vpc_id
  service_account_id            = dependency.sa_serverless_deploy.outputs.sa_id
  container_id                  = dependency.serverless_container.outputs.container_id
  container_resources           = dependency.serverless_container.outputs.container_resources # get all, then send with grpc
  registry_id                   = dependency.registry.outputs.registry_id
  create_image_tag              = true
  sa_key_path                   = "${local.work_dir}/secrets/ops/yc_serverless_deploy_sa_key.json"
  bucket_name                   =  "project-dildakot--yc-backend--dmvlelmn"
  object_name                   = "${path_relative_to_include()}/restart-function.zip"



  # RESOURCES
  name                          = "restart-website-container-on-latest-push"
  image_name                    = "${dependency.registry.outputs.registry_id}/${split("/", split(":", dependency.serverless_container.outputs.image_url)[0])[2]}" # "registry_id/image_name"
  image_tag                     = "latest"
  image_url                     = "cr.yandex/${dependency.registry.outputs.registry_id}/${local.app}-${local.service}:latest"
  batch_cutoff                  = "0"
  batch_size                    = "1"
}
