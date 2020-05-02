ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw enable
systemctl enable ufw --now
