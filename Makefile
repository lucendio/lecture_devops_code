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


ENVIRONMENT ?= local
PLAYBOOK ?= main

export ANSIBLE_LOG_PATH = $(MKFILE_DIR)/ansible.log
export ANSIBLE_ROLES_PATH = $(MKFILE_DIR)/cm-ansible/roles



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
		dev-env.vagrant.local


.PHONY: vm-start
.SILENT: vm-start
vm-start: export VM_PRIVILEGED_USERNAME = $(PRIVILEGED_USERNAME)
vm-start: export VM_SSH_PUB_KEY_PATH = $(SSH_KEY_PAIR_PATH).pub
vm-start:
	vagrant up --no-provision

.PHONY: vm-stop
.SILENT: vm-stop
vm-stop: export VM_PRIVILEGED_USERNAME = $(PRIVILEGED_USERNAME)
vm-stop: export VM_SSH_PUB_KEY_PATH = $(SSH_KEY_PAIR_PATH).pub
vm-stop:
	vagrant halt

.PHONY: vm-status
.SILENT: vm-status
vm-status: export VM_SSH_PUB_KEY_PATH = $(SSH_KEY_PAIR_PATH).pub
vm-status:
	vagrant status


.PHONY: vm-clean
.SILENT: vm-clean
vm-clean: export VM_SSH_PUB_KEY_PATH = $(SSH_KEY_PAIR_PATH).pub
vm-clean:
	vagrant destroy -f
	rm -rf \
		$(VAGRANT_DOTFILE_PATH) \
		$(MKFILE_DIR)/*.log



.PHONY: facts
.SILENT: facts
facts: export ANSIBLE_CONFIG = $(MKFILE_DIR)/environments/$(ENVIRONMENT)/ansible.cfg
facts:
	ansible \
		--module-name=setup \
		--inventory=$(MKFILE_DIR)/environments/$(ENVIRONMENT)/inventory \
		all

.PHONY: vars
.SILENT: vars
vars: export ANSIBLE_CONFIG = $(MKFILE_DIR)/environments/$(ENVIRONMENT)/ansible.cfg
vars:
	ansible \
		--module-name=debug \
		--args="var=vars" \
		--inventory=$(MKFILE_DIR)/environments/$(ENVIRONMENT)/inventory \
		all

.PHONY: check
.SILENT: check
check:
	ansible-playbook \
		--syntax-check \
		--inventory=$(MKFILE_DIR)/environments/$(ENVIRONMENT)/inventory \
		$(MKFILE_DIR)/cm-ansible/playbooks/$(PLAYBOOK).yaml


.PHONY: bootstrap
.SILENT: bootstrap
bootstrap:
	mkdir -p $(MKFILE_DIR)/.logs
	ansible-playbook \
		--inventory=$(MKFILE_DIR)/environments/$(ENVIRONMENT)/inventory \
		$(MKFILE_DIR)/cm-ansible/playbooks/$(PLAYBOOK).yaml


.PHONY: local
.SILENT: local
local: ENVIRONMENT = local
local: export ANSIBLE_CONFIG = $(MKFILE_DIR)/environments/$(ENVIRONMENT)/ansible.cfg
local: bootstrap

test-local: PLAYBOOK = test
test-local: local
