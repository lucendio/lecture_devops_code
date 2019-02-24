.PHONY: default allocate bootstrap install clean
.SILENT: restore snapshot
.DEFAULT_GOAL := default


CWD = $(CURDIR)


SSH_KEY_PAIR_PATH ?= $(CWD)/.credentials/ssh-key
CREDENTIALS_DIR_PATH = $(shell dirname $(SSH_KEY_PAIR_PATH))
TERRAFORM_DIR_PATH = $(CWD)/do-tf
TERRAFORM_PLAN_FILE_PATH = $(CWD)/terraform.plan
TERRAFORM_STATE_FILE_PATH = $(CWD)/terraform.tfstate


digitaloceanApiToken = $(shell cat $(CREDENTIALS_DIR_PATH)/do-api-token)


export TF_LOG =
export TF_DATA_DIR = $(CWD)/.terraform



default: allocate bootstrap


init:
	@mkdir -p $(CREDENTIALS_DIR_PATH)
	@ssh-keygen \
		-t rsa \
		-b 4096 \
		-f $(SSH_KEY_PAIR_PATH) \
		-C "test@terraform-on-mobile" -N '' 2>&1> /dev/null
	@mv $(SSH_KEY_PAIR_PATH) $(SSH_KEY_PAIR_PATH).prv
	@terraform init \
		-input=false \
		$(TERRAFORM_DIR_PATH)


allocate:
	@cd $(TERRAFORM_DIR_PATH) && \
		terraform plan \
			-var "DO_API_TOKEN=$(digitaloceanApiToken)" \
			-var "sshKeyPairPath=$(SSH_KEY_PAIR_PATH)" \
			-state=$(TERRAFORM_STATE_FILE_PATH) \
			-out=$(TERRAFORM_PLAN_FILE_PATH) \
			$(TERRAFORM_DIR_PATH)
	@terraform apply \
		$(TERRAFORM_PLAN_FILE_PATH)


bootstrap:
	echo "TODO"


install: setup allocate bootstrap


connect:
	@ssh \
		-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
		-p 22 \
		-l root \
		-i $(SSH_KEY_PAIR_PATH).prv \
		$(shell terraform output -state=$(TERRAFORM_STATE_FILE_PATH) 'vm-ipv4')


clean:
	@cd $(TERRAFORM_DIR_PATH) && \
		terraform destroy \
			-auto-approve \
			-var "DO_API_TOKEN=$(digitaloceanApiToken)" \
			-var "sshKeyPairPath=$(SSH_KEY_PAIR_PATH)" \
			-state=$(TERRAFORM_STATE_FILE_PATH) \
			$(TERRAFORM_DIR_PATH)
	@rm -rf \
		$(TF_DATA_DIR) \
		$(TERRAFORM_STATE_FILE_PATH)* \
		$(TERRAFORM_PLAN_FILE_PATH)
