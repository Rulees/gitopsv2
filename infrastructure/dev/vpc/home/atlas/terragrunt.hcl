terraform {
  source = "${get_repo_root()}/modules/dbs//atlas/"
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "postgresql" {
  config_path                             = "../postgresql"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "providers", "terragrunt-info", "show"]
  mock_outputs  = {
    db_engine           = "postgresql"
    db_login             = "user"
    db_password         = "12ggg3456"
    db_port             = "6432"
    cluster_master_fqdn = "c-123134.rw.mdb.yandexcloud.net"
    db_name             = "cars"
    database_url        = "getger"
  }
}


inputs = {

  # MAIN
  dev_url               = "docker://postgres/17/test"                                                                                                       # docker://db_engine/db_version/db_name
  url                   = "${dependency.postgresql.outputs.db_engine}://${dependency.postgresql.outputs.db_login}:${dependency.postgresql.outputs.db_password}@${dependency.postgresql.outputs.cluster_master_fqdn}:${dependency.postgresql.outputs.db_port}/${dependency.postgresql.outputs.db_name}?sslmode=verify-full&sslrootcert=./secrets/not_secrets/root.crt"
  src                   = file("${get_terragrunt_dir()}/schema.pg.hcl")
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
