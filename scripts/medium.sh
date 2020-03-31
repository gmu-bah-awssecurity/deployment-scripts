#!/usr/bin/env bash
# deployment script for ec2 - med variant

if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root."
    exit
fi

# UPDATE INSTANCE
apt update -y && apt upgrade -y

# INSTALL NICE-TO-HAVES
apt install -y tmux vim htop

# INSTALL NECESSARY ADDITIONS
add-apt-repository ppa:mrazavi/openvas
apt install -y $(cat pkglist)

