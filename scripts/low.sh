#!/usr/bin/env bash
# deployment script for ec2 - low variant
# test
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root."
    exit
fi

INTERFACE=$(ip l | grep "2: " | cut -d' ' -f2 | cut -d: -f1)
ADDR=$(ip -o -f inet a | grep $INTERFACE | cut -d' ' -f7 | sed "s:/.*::g")
CIDR=$(ip -o -f inet a | grep $INTERFACE | cut -d' ' -f7)
SUBNET=$(ip r | grep -v default | cut -d' ' -f1 | grep /)
FOURTH_IP="172.31.16.58"

# UPDATE INSTANCE
apt update -y && apt upgrade -y

# INSTALL NICE-TO-HAVES
apt install -y tmux vim htop

# INSTALL NECESSARY ADDITIONS
apt install -y bro broctl rsync snort fail2ban ufw

# CLEAN UP UNUSED PACKAGES
apt autoremove -y

# snort

#edit local.rules file for sensitive-data rules, local.rules already exists but its empty
cat << EOF >> /etc/snort/rules/local.rules
#sensitive-data rules
alert tcp HOME_NET any -> EXTERNAL_NET [80,20,25,143,110] (msg:"SENSITIVE-DATA Credit Card Numbers"; metadata:service http, service smtp, service ftp-data, service imap, service pop3; sd_pattern:2,credit_card; classtype:sdf; sid:2; gid:138; rev:1;)
alert tcp HOME_NET any -> EXTERNAL_NET [80,20,25,143,110] (msg:"SENSITIVE-DATA U.S. Social Security Numbers (with dashes)"; metadata:service http, service smtp, service ftp-data, service imap, service pop3; sd_pattern:2,us_social; classtype:sdf; sid:3; gid:138; rev:1;)
alert tcp HOME_NET any -> EXTERNAL_NET [80,20,25,143,110] (msg:"SENSITIVE-DATA U.S. Social Security Numbers (w/out dashes)"; metadata:service http, service smtp, service ftp-data, service imap, service pop3; sd_pattern:20,us_social_nodashes; classtype:sdf; sid:4; gid:138; rev:1;)
alert tcp HOME_NET any -> EXTERNAL_NET [80,20,25,143,110] (msg:"SENSITIVE-DATA Email Addresses"; metadata:service http, service smtp, service ftp-data, service imap, service pop3; sd_pattern:20,email; classtype:sdf; sid:5; gid:138; rev:1;)
alert tcp HOME_NET any -> EXTERNAL_NET [80,20,25,143,110] (msg:"SENSITIVE-DATA U.S. Phone Numbers"; metadata:service http, service smtp, service ftp-data, service imap, service pop3; sd_pattern:20,(\d{3}) ?\d{3}-\d{4}; classtype:sdf; sid:6; gid:138; rev:1;)
EOF

sed -i "s:^ipvar HOME_NET any$:ipvar HOME_NET $CIDR:g" /etc/snort/snort.conf
sed -i 's/.\(config logdir:*.\)/\1/g' /etc/snort/snort.conf   #I really don't know what the .*/*. is or what order to put it in or if i even need it
#I found this command and maybe it can uncomment and add on the filepath i need all in one command?
sed -i 'sX\#config logdir:.*Xconfig logdir: /var/log/snortX' /etc/snort/snort.conf
#comment out 'output unified: filename snort.log...'
sed -i 's/output log_unified2: filename snort.log, limit 128, nostamp.*/#&/g' /etc/snort/snort.conf
#comment in syslog 'output alert_syslog: LOG_AUTH LOG_ALERT'
sed -i 's/.\(output alert_syslog: LOG_AUTH LOG_ALERT.*\)/\1/g' /etc/snort/snort.conf

#run config file to check for errors
snort -c /etc/snort/snort.conf -T || exit

#command to run snort
systemctl enable snort --now


# bro

sed -i "s/eth0/$INTERFACE/g" /etc/bro/node.cfg
cat << EOF > /etc/bro/networks.cfg
$SUBNET Private IP space
EOF

broctl install
broctl cron enable
broctl deploy || exit


# ufw

ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw enable || exit
systemctl enable ufw --now

# f2b

cat << EOF >> /etc/fail2ban/jail.local
[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
EOF

systemctl enable fail2ban --now

# sshd

sed -i "s/#MaxAuthTries 6/MaxAuthTries 3/g" /etc/ssh/sshd_config
sed -i "s/#MaxSessions 10/MaxSessions 5/g" /etc/ssh/sshd_config

systemctl restart sshd
