Lecture: DevOps - Code Examples
===============================


This repository contains executable code that is meant to serve as examples
for the __DevOps__ lecture as part of the master's studies.


## Example: Terraform

### Requirements

*   `make`
*   `openssh`
*   `terraform`
*   r/w supporting DigitalOcean API token (`./.credentials/do-api-token`)


### How to use

1. `make init`
    *   generates an ssh key pair
    *   initializes terraform within the project 

2. `make allocate`
    *   spins up a virtual machine

3. `make connect`
    *   opens ssh connection to the virtual machine

4. `make clean`
    *   destroys all allocated resources on DigitalOcean
    *   removes all terraform files created during runtime 


## Example: Vagrant

### Requirements

*   `make`
*   `openssh`
*   `vagrant`
*   VirtualBox (+ Extension Pack and Guest Additions)


### How to use

1. `make vm-prerequisites`
    *   installs depending vagrant plugins

2. `make vm-allocate`
    *   spins up and prepares a local virtual machine 

3. `make vm-connect`
    *   opens ssh connection to the virtual machine

4. `make vm-clean`
    *   destroys the local virtual machine
    *   removes all vagrant files and logs created during runtime 


## Example: Ansible 

### Requirements

*   `make`
*   `ansible` v2.8.x
*   per default the target host is the one provisioned in __Example: Vagrant__,
    so unless another host has been added in the inventory, it is required to 
    allocate the local virtual machine first before applying the environment 
    configuration with Ansible
    
### Project structure

*   `./environments/local/inventory` contains all arguments for the local 
    environment
*   `./cm-ansible/roles` contains the whole state definition and logic
*   `./cm-ansible/playbooks` 

### How to use

0. `make vm` (optional, if not already done)
    * spins up the local virtual machine

1. `make local`
    * applies configuration for the local environment
    
2.  `make test-local`
    * executes all tests defined in the respective roles
    
Please note that the `Makefile` contains some more "sub-commands" (aka *target*)
worth checking out regarding Ansible, like `facts`, `vars` or `check`.
