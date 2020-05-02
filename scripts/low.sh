#!/usr/bin/env bash
# deployment script for ec2 - low variant
# test
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root."
    exit
fi

ADDR=$(ip -o -f inet a | grep eth0 | cut -d' ' -f7 | sed "s:/.*::g")
CIDR=$(ip -o -f inet a | grep eth0 | cut -d' ' -f7)
SUBNET=$(ip r | grep -v default | cut -d' ' -f1)
INTERFACE="eth0"

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
alert tcp $HOME_NET any -> any any (msg:”SSN in Clear Text”; pcre:”/[0-9]{3,3}\-[0-9]{2,2}\-[0-9]{4,4}/”; sid:1000016; rev:1;)
alert tcp $HOME_NET any -> $EXTERNAL_NET [80,20,25,143,110] (msg:"SENSITIVE-DATA Credit Card Numbers"; metadata:service http, service smtp, service ftp-data, service imap, service pop3; sd_pattern:2,credit_card; classtype:sdf; sid:2; gid:138; rev:1;)
alert tcp $HOME_NET any -> $EXTERNAL_NET [80,20,25,143,110] (msg:"SENSITIVE-DATA U.S. Social Security Numbers (with dashes)"; metadata:service http, service smtp, service ftp-data, service imap, service pop3; sd_pattern:2,us_social; classtype:sdf; sid:3; gid:138; rev:1;)
alert tcp $HOME_NET any -> $EXTERNAL_NET [80,20,25,143,110] (msg:"SENSITIVE-DATA U.S. Social Security Numbers (w/out dashes)"; metadata:service http, service smtp, service ftp-data, service imap, service pop3; sd_pattern:20,us_social_nodashes; classtype:sdf; sid:4; gid:138; rev:1;)
alert tcp $HOME_NET any -> $EXTERNAL_NET [80,20,25,143,110] (msg:"SENSITIVE-DATA Email Addresses"; metadata:service http, service smtp, service ftp-data, service imap, service pop3; sd_pattern:20,email; classtype:sdf; sid:5; gid:138; rev:1;)
alert tcp $HOME_NET any -> $EXTERNAL_NET [80,20,25,143,110] (msg:"SENSITIVE-DATA U.S. Phone Numbers"; metadata:service http, service smtp, service ftp-data, service imap, service pop3; sd_pattern:20,(\d{3}) ?\d{3}-\d{4}; classtype:sdf; sid:6; gid:138; rev:1;)
#SQL injection attempt
alert tcp any any -> $HOME_NET any (msg:”SQL Injection Attempt”; pcre:”/\w*((\%27)|(\’))((\%6F)|o|(\%4F))((\%72)|r|(\%52))/ix”; sid:1000017; rev:1;)'
EOF

sed -i "s:^ipvar HOME_NET any$:ipvar HOME_NET $CIDR:g" /etc/snort/snort.conf
sed -i 's/.\(config logdir:*.\)/\1/g' snort.conf   #I really don't know what the .*/*. is or what order to put it in or if i even need it
#I found this command and maybe it can uncomment and add on the filepath i need all in one command?
sed -i 'sX\#config logdir:.*Xconfig logdir: /var/log/snort' /etc/snort/snort.conf
#comment out 'output unified: filename snort.log...'
sed -i 's/output log_unified2: filename snort.log, limit 128, nostamp.*/#&/g' /etc/snort/snort.conf
#comment in syslog 'output alert_syslog: LOG_AUTH LOG_ALERT'
sed -i 's/.\(output alert_syslog: LOG_AUTH LOG_ALERT.*\)/\1/g' /etc/snort/snort.conf

#run config file to check for errors
snort -c /etc/snort/snort.conf -T || exit

#command to run snort
systemctl enable snort --now


# bro

cat << EOF > /etc/bro/networks.cfg
$SUBNET Private IP space
EOF

broctl install
broctl cron enable
broctl deploy


# ufw

ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw enablesystemctl enable ufw --now

# f2b, rsync, etc
