Terrafrom on mobile POC
=======================

This projects aims to implement a proof-of-concepts, of 


## Requirements

*   `make`
*   `trerrafrom`


## Preparations

Create the file `./.credentials/do-api-token` and add a r/w supporting DigitalOcean API token


## How to use

0. make sure you already took care of the preparations 

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
