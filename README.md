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
*   VirtualBox


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
