#!/usr/bin/env bash

IDENTITY=$1

if [ "$#" -gt 2 ]; then
    PUBKEY=$(ssh -i $IDENTITY ubuntu@$2 'sudo cat /root/.ssh/id_rsa.pub')
else
    echo "Not enough arguments"
    echo "Usage:"
    echo "rsync-setup.sh <ssh identity> <management instance ip> [list of ip addresses to manage]"
    exit
fi

shift
shift

for ip in "$@"; do
    ssh -i $IDENTITY ubuntu@$1 "echo $PUBKEY | sudo tee -a /root/.ssh/authorized_keys"
    (crontab -l 2>/dev/null; echo "") | crontab -
    shift
done

