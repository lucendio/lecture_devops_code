SHELL := '/bin/bash'

.DEFAULT_GOAL := default

MKFILE_DIR = $(abspath $(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
CWD ?= $(CURDIR)



SSH_KEY_PAIR_PATH ?= $(MKFILE_DIR)/.credentials/ssh-key
CREDENTIALS_DIR_PATH = $(shell dirname $(SSH_KEY_PAIR_PATH))
TERRAFORM_DIR_PATH = $(MKFILE_DIR)/do-tf
TERRAFORM_PLAN_FILE_PATH = $(MKFILE_DIR)/terraform.plan
TERRAFORM_STATE_FILE_PATH = $(MKFILE_DIR)/terraform.tfstate


export TF_LOG =
export TF_DATA_DIR = $(MKFILE_DIR)/.terraform



default: init allocate


.SILENT: $(CREDENTIALS_DIR_PATH)/do-api-token
$(CREDENTIALS_DIR_PATH)/do-api-token:
	echo "DigitalOcean API token does not exist!" \
	&& exit 1

.SILENT: $(SSH_KEY_PAIR_PATH).prv
$(SSH_KEY_PAIR_PATH).prv:
	mkdir -p $(CREDENTIALS_DIR_PATH)
	ssh-keygen \
		-t rsa \
		-b 4096 \
		-f $(SSH_KEY_PAIR_PATH) \
		-C "test@terraform-on-mobile" -N '' 2>&1> /dev/null
	mv $(SSH_KEY_PAIR_PATH) $(SSH_KEY_PAIR_PATH).prv

.SILENT: $(MKFILE_DIR)/.terraform
$(MKFILE_DIR)/.terraform:
	terraform init \
		-input=false \
		$(TERRAFORM_DIR_PATH)

.SILENT: init
.PHONY: init
init: $(SSH_KEY_PAIR_PATH).prv $(CREDENTIALS_DIR_PATH)/do-api-token $(MKFILE_DIR)/.terraform


.SILENT: allocate
.PHONY: allocate
allocate: init
allocate:
	terraform plan \
		-var "DO_API_TOKEN=$(shell cat $(CREDENTIALS_DIR_PATH)/do-api-token)" \
		-var "sshKeyPairPath=$(SSH_KEY_PAIR_PATH)" \
		-state=$(TERRAFORM_STATE_FILE_PATH) \
		-out=$(TERRAFORM_PLAN_FILE_PATH) \
		$(TERRAFORM_DIR_PATH)
	terraform apply \
		$(TERRAFORM_PLAN_FILE_PATH)


.SILENT: provision
.PHONY: provision
provision:
	echo "TODO"


.SILENT: install
.PHONY: install
install: init allocate provision


.SILENT: connect
.PHONY: connect
connect:
	ssh \
		-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
		-p 22 \
		-l root \
		-i $(SSH_KEY_PAIR_PATH).prv \
		$(shell terraform output -state=$(TERRAFORM_STATE_FILE_PATH) 'vm-ipv4')


.SILENT: clean
.PHONY: clean
clean: $(MKFILE_DIR)/.terraform
clean:
	terraform destroy \
		-auto-approve \
		-var "DO_API_TOKEN=$(shell cat $(CREDENTIALS_DIR_PATH)/do-api-token)" \
		-var "sshKeyPairPath=$(SSH_KEY_PAIR_PATH)" \
		-state=$(TERRAFORM_STATE_FILE_PATH) \
		$(TERRAFORM_DIR_PATH)
	rm -rf \
		$(TF_DATA_DIR) \
		$(TERRAFORM_STATE_FILE_PATH)* \
		$(TERRAFORM_PLAN_FILE_PATH)
