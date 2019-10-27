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


PRIVILEGED_USERNAME = provisioner

export VAGRANT_DOTFILE_PATH = $(MKFILE_DIR)/.vagrant
export VAGRANT_CWD = $(MKFILE_DIR)/environments/local



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
		-C "$(PRIVILEGED_USERNAME)" -N '' 2>&1> /dev/null
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

.SILENT: configure
.PHONY: configure
configure:
	echo "TODO"

.SILENT: install
.PHONY: install
install: init allocate configure


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




.PHONY: vm-prerequisites
.SILENT: vm-prerequisites
vm-prerequisites:
	vagrant plugin install \
		vagrant-vbguest \
		vagrant-hostmanager

.PHONY: vm-spinup
.SILENT: vm-spinup
vm-spinup: export VM_PRIVILEGED_USERNAME = $(PRIVILEGED_USERNAME)
vm-spinup: export VM_SSH_PUB_KEY_PATH = $(SSH_KEY_PAIR_PATH).pub
vm-spinup: $(SSH_KEY_PAIR_PATH).prv
vm-spinup:
	vagrant up --no-provision

.PHONY: vm-prepare
.SILENT: vm-prepare
vm-prepare: export VM_PRIVILEGED_USERNAME = $(PRIVILEGED_USERNAME)
vm-prepare: export VM_SSH_PUB_KEY_PATH = $(SSH_KEY_PAIR_PATH).pub
vm-prepare: $(SSH_KEY_PAIR_PATH).prv
vm-prepare:
	vagrant provision

.PHONY: vm-allocate
.SILENT: vm-allocate
vm-allocate: vm-spinup vm-prepare


.PHONY: vm
.SILENT: vm
vm: vm-prerequisites vm-spinup vm-prepare


.PHONY: vm-connect
.SILENT: vm-connect
vm-connect: $(SSH_KEY_PAIR_PATH).prv
vm-connect:
	ssh \
		-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
		-p 22 \
		-l $(PRIVILEGED_USERNAME) \
		-i $(SSH_KEY_PAIR_PATH).prv \
		local-dev-env.vagrant.local


.PHONY: vm-start
.SILENT: vm-start
vm-start:
	vagrant up --no-provision

.PHONY: vm-stop
.SILENT: vm-stop
vm-stop:
	vagrant halt


.PHONY: vm-clean
.SILENT: vm-clean
vm-clean: export VM_SSH_PUB_KEY_PATH = $(SSH_KEY_PAIR_PATH).pub
vm-clean:
	vagrant destroy -f
	rm -rf \
		$(VAGRANT_DOTFILE_PATH) \
		$(MKFILE_DIR)/*.log
