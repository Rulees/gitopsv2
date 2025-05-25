terraform {
  source = "${get_repo_root()}/modules//sa"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  sa_name        = "serverless-deploy"
}

inputs = {
  create_mode    = false # Follow README.md
  project_prefix = include.root.locals.project_prefix
  folder_id      = include.root.locals.folder_id
  sa_name        = local.sa_name
  roles = [
  "resource-manager.viewer",
  "storage.uploader",
  "container-registry.images.pusher",
  "container-registry.viewer",
  "serverless-containers.editor",
  "iam.serviceAccounts.tokenCreator",
  "functions.admin",
  "vpc.user",
  "iam.serviceAccounts.user"
  ]
  key_path       = "${get_repo_root()}/secrets/ops/yc_${replace(local.sa_name, "-", "_")}_sa_key.json"
}