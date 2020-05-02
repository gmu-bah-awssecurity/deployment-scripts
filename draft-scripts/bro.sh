apt install bro broctl

cat << EOF > /etc/bro/networks.cfg
$SUBNET Private IP space
EOF

broctl install
broctl cron enable
broctl deploy

