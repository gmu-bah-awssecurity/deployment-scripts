#!/usr/bin/env bash

RSYNC_START="rsync -a -zz -e ssh"
RSYNC_DEST="/var/instance-logs"

while getopts "i:f:l:m:h:" arg; do
    case $arg in
        i)
            ID=$OPTARG
            ;;
        f)
            MANAGEMENT=$OPTARG
            PUBKEY=$(ssh -i $ID ubuntu@$OPTARG 'sudo cat /root/.ssh/id_rsa.pub')
            ;;
        l)
            ssh -i $ID ubuntu@$MANAGEMENT "sudo mkdir -p $RSYNC_DEST/$OPTARG && sudo ssh-keyscan -H $OPTARG >> ~/.ssh/known_hosts"
            ssh -i $ID ubuntu@$OPTARG "echo $PUBKEY | sudo tee -a /root/.ssh/authorized_keys"
            ssh -i $ID ubuntu@$MANAGEMENT "echo 0 */2 \* \* \* $RSYNC_START $OPTARG:/var/log $RSYNC_DEST/$OPTARG | sudo tee -a /var/spool/cron/crontabs/root"
            ;;
        m)
            ssh -i $ID ubuntu@$MANAGEMENT "sudo mkdir -p $RSYNC_DEST/$OPTARG && sudo ssh-keyscan -H $OPTARG >> ~/.ssh/known_hosts"
            ssh -i $ID ubuntu@$OPTARG "echo $PUBKEY | sudo tee -a /root/.ssh/authorized_keys"
            ssh -i $ID ubuntu@$MANAGEMENT "echo 0 \* \* \* \* $RSYNC_START $OPTARG:/var/log $RSYNC_DEST/$OPTARG | sudo tee -a /var/spool/cron/crontabs/root"
            ;;
        h)
            ssh -i $ID ubuntu@$MANAGEMENT "sudo mkdir -p $RSYNC_DEST/$OPTARG && sudo ssh-keyscan -H $OPTARG >> ~/.ssh/known_hosts"
            ssh -i $ID ubuntu@$OPTARG "echo $PUBKEY | sudo tee -a /root/.ssh/authorized_keys"
            ssh -i $ID ubuntu@$MANAGEMENT "echo */15 \* \* \* \* $RSYNC_START $OPTARG:/var/log $RSYNC_DEST/$OPTARG | sudo tee -a /var/spool/cron/crontabs/root"
            ;;
        \?)
            echo "Usage:"
            echo "rsync-setup.sh"
            echo "    -i <ssh identity>"
            echo "    -f <management instance ip or hostname>"
            echo ""
            echo "    -l <low-security instance ip or hostname>"
            echo "    -m <med-security instance ip or hostname>"
            echo "    -h <high-security instance ip or hostname>"
            echo ""
            echo "Make sure you enter each low/med/high security instance with its own '-l', '-m', or '-h'."
            exit
            ;;
    esac
done

