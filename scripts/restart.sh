#!/usr/bin/env bash

# run as root

cat /var/log/apt/history.log | grep install | rev | cut -d" " -f1 | rev | xargs apt purge -y

cat /var/log/apt/history.log | grep install | rev | cut -d" " -f1 | rev | xargs apt-get purge -y

apt autoremove -y
