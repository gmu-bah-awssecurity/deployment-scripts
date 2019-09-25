#!/bin/bash
# deployment script for ec2 - low variant

# UPDATE INSTANCE
yum update -y

# INSTALL NECESSARY ADDITIONS
yum install python3 -y

# INSTALL NICE-TO-HAVES
yum install tmux -y
yum install vim -y
yum install htop -y