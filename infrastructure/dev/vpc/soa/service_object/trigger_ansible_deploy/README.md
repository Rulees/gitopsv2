# Playbook can be triggereed only by SUBSERVICE=trigger_ansible_deploy(not general ENV=dev)
# Playbook will be deployed on service-level infrastructure, cause of specific param. This param is always specified inside subservice-level playbook.yml to avoid using infra of subservice. Because in most cases here is no infra.
