ENV ?=
APP ?=
SERVICE ?=
SUBSERVICE ?=

.PHONY: check_secrets decrypt_secrets create deploy approve destroy

check_secrets:
	bash scripts/ci/10-check-secrets.sh

decrypt_secrets:
	bash scripts/ci/20-decrypt-secrets.sh

create:
	python3 scripts/ci/30-create.py $(ENV) $(APP) $(SERVICE)

deploy:
	scripts/ci/40-deploy.py $(ENV) $(APP) $(SERVICE)

approve:
	bash scripts/ci/50-approve.sh

destroy:
	python3 scripts/ci/60-destroy.py $(ENV) $(APP) $(SERVICE)



add_tag_deploy_status:
	python3 scripts/ci/add_tag_deploy_status.py successful_hosts.txt