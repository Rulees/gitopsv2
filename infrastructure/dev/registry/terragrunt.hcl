terraform {
  source = "${get_repo_root()}/modules//registry/"
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

inputs = {
  env  = include.root.locals.env_vars.locals.env
}