# Gitops project with using:
- Yandex Cloud:              Cloud Provider(where infra/apps creation happens) 
- Terragrunt/Terraform:      Create infrastructure(vms,dbs,dns..) in Yandex Cloud
- Ansible:                   Deploy applications(website, telgrambot..) to infrastructure
- SOPS:                      Encrypt secrets in gitlab repository
- GitLab:                    Connect all tools in one by describing main stages in pipiline(.gitlab-ci.yml)

- /modules:                  modules for terragrunt
- /infrastructure:           ansible + infra(symbol <_> is used to describe resources that require manual actions at first launch)
- /projects:                 developer's code + Dockerfile
- /secrets:                  Storage of secrets
- /scripts:                  Scripts for ci/cd, manual actions
- .sops.yaml:                Assign what files/folder has to be encrypted and which private key has to be used for this
- makefile:                  Main steps for gitlab pipiline are described inside makefile to avoid long names of scripts inside .gitlab-ci.yml
- .gitlab-ci.yml:            Pipiline to avoid manual actions: .. > dev_env > approve > prod_env > ..

# Features:
- Structure of folders has strict order: /infrastructure/{env}/{app}/{service}/{subservice}. It lets to assign labels for resources(vm's..) based on their location.
- These labels can be used to create/destroy/deploy only specific resource.

# Stages:
1)  check_secrets
2)  create_dev
3)  deploy_dev
4)  approve
5)  create_prod
6)  deploy_prod
7)  destroy

# MANUALLY
- GITLAB PROJECT(create project, restrict push into main branch, only merge from feature-branch is allowed)
- Terraform/Terragrunt(backend_, sa_ )
- SOPS KEYS(create keys, describe using of them inside .sops.yaml, add secrets into /secrets, encrypt everyhting)
- /scripts/send_vars_to_gitlab.sh (SOPS_KEYS, people assigned to approve merge requsts)

# AUTOMATICALLY
1) - 10-check-secrets.sh . Check /secrets and /scripts/send_vars.. for revealed secrets

2) - 20-decrypt-secrets.sh  is used in all stages, that require decrypting secrets. It decrypts only special dirs inside /secrets according to values specified inside .gitlab-ci.yml "variables: SOPSKEYS: '<dir_name> <dir_name> <dir_name>'". These values indicate to private-sops-keys that we are gonna use to decrypt secrets(Secrets can be decrypted only with keys, that were used to encrypt them)
   - 30-create.py uses terragrunt to create resources(vm's...) with ENV=dev  +  assign labels to resources according to their sctrict location inside project: /infrastructure/{env}/{app}/{service}/{subservice}. Example: /infrastructure/dev/totemlounge/website will assign 3 labels: env=dev app=totemlounge service=website.

3) - 40-deploy.py is used to apply ansible-playbooks to created infrastructure. Ansible Dynamic Inventory /infrastructure/ansible/yc_compute.py is used to create host_groups from labels of resources assigned with terragrunt and their project location in previous stage. It creates almost all of the combination from small to big with symbols "_" between label_name:label_value and "__" between different labels.  For example: env_dev__app_totemlounge__service_telegrambot or env_prod__service_website
   - Playbook basicly uses Docker to build image and run container. This location /projects/{app}/{service}/{subservice} is used for Dockerfile and applications code. So developers has to write their code here.

4) - 50-approve.sh is used to allow approving merge request only by someone experienced in organization, for a case if somebody has writed bad application code, after that commit happens and prod_env starts. Experienced persons are assigned by gitlab_vars: APPROVERS_ARRAY(list of people who can approve changes in basic developer's folder "/projects" and secrets for developers "/secrets/{env}/.../.env") and APPROVERS_INFRA_ARRAY(list of people who can approve changes in all other folders). Stage waits only for a specified time and has to be restarted if necessary.

5) - Create prod infrastructure

6) - Deploy apps to prod env

7) - Manual stage to destroy dev/prod


# DEVELOPS TIPS
1) create feature branch, make changes, push to you branch and do merge requst, if you want to see result of code in dev environment and pipiline status for your code. If you want to get approve then create merge request
2) If you need to change .env with secrets for your app you need to get sops-private-key from admin. You can decrypt secrets with command: cd ~/project_gitlab && find secrets/ -type f -exec sops --decrypt --in-place {} \; . Then do not forget to encrypt it with command cd ~/project_gitlab && find secrets/ -type f -exec sops --encrypt --in-place {} \;
. Without encrypting pipiline fails. Example for installation "sops" stored inside /scripts/ci/20-decrypt-secrets.sh

# Errors
For now if several commits happens at once, then approve stage will fail




# NEXT STAGE
1) We have autoscale with IG for every service. and service can talk with each other by nginx /location to upstreams with these services or talk by consul dns without nginx.
2) Frontend with react
3) DATABASE postgresql + atlas for creating schema + service to work with this db +