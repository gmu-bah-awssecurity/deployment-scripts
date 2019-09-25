#!/bin/bash
# deployment script for ec2 - high variant

# UPDATE INSTANCE
yum update -y

# INSTALL NECESSARY ADDITIONS
yum install python3 -y

# INSTALL NICE-TO-HAVES
yum install tmux -y
yum install vim -y
