terraform {
  source = "${get_repo_root()}/modules/dbs//atlas/"
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "postgresql-bd" {
  config_path                             = "../postgresql"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "providers", "terragrunt-info", "show"]
  mock_outputs  = {
    db_engine           = "postgresql"
    db_user             = "user"
    db_password         = "123456"
    db_port             = "6432"
    db_name             = "cars"
    cluster_master_fqdn = "123134.rw.mdb.yandexcloud.net"
  }
}

locals {
  db_engine             = dependency.postgresql-bd.outputs.db_engine
  db_user               = dependency.postgresql-bd.outputs.db_user
  db_password           = dependency.postgresql-bd.outputs.db_password
  db_port               = dependency.postgresql-bd.outputs.db_port
  cluster_master_fqdn   = dependency.postgresql-bd.outputs.db_url
  db_name               = dependency.postgresql-bd.outputs.db_name
}


inputs = {
  # MAIN
  dev_url               = "docker://mysql/8/test"                                                                                                      # docker://db_engine/db_version/db_name
  url                   = "${local.db_engine}://${local.db_user}:${local.db_password}@${local.cluster_master_fqdn}:${local.db_port}/${local.db_name}"  # mysql://root:pass@localhost:3306/myapp , if local
  src                   = file("${get_terragrunt_dir()}/schema.hcl")
  concurrent_index = {
    create              = true
    drop                = true
  }

##
# NOT FREE
##
  # lint_review_mode      = "ERROR" # dev=warn, prod=error
  # lint_review_time      = "10s"
}