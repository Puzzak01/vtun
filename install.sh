#!/bin/bash

apt update
apt install -y arping bridge-utils dnsmasq iptables net-tools inetutils-inetd

FILE="/etc/network/interfaces"
LINE="source /etc/network/interfaces.d/*"

if [ -f "$FILE" ] && ! grep -Fxq "$LINE" "$FILE"; then
    echo "" >> "$FILE"
    echo "$LINE" >> "$FILE"
fi

echo -e "auto br-ipcam\niface br-ipcam inet static\n    address 172.16.0.1\n    netmask 255.255.0.0\n    bridge_ports zero\n    up mkdir -p /var/lock/vtund /var/log/vtund" >/etc/network/interfaces.d/br-ipcam

ifup -v br-ipcam

wget -O /etc/dnsmasq.conf https://raw.githubusercontent.com/Puzzak01/vtun/refs/heads/main/dnsmasq.conf

{
echo '5000    stream  tcp     nowait  root    /usr/local/bin/vtund vtund -i -f /etc/vtund.conf'
} > /etc/inetd.conf

systemctl restart dnsmasq
systemctl restart inetutils-inetd

sysctl -w net.ipv4.ip_forward=1 && grep -q '^net.ipv4.ip_forward=1' /etc/sysctl.conf || echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf && sysctl -p /etc/sysctl.conf

touch /etc/vtund.dhcp

wget -O /usr/local/bin/vtund https://github.com/Puzzak01/vtun/raw/refs/heads/main/vtund
chmod +x /usr/local/bin/vtund

wget -O /etc/vtund.conf https://raw.githubusercontent.com/Puzzak01/vtun/refs/heads/main/vtund.conf

{
echo ''
echo '[Unit]'
echo 'Description=VTUN tunnel'
echo 'After=network.target'
echo ''
echo '[Service]'
echo 'Type=simple'
echo 'ExecStart=/usr/local/bin/vtund -n -s -f /etc/vtund.conf'
echo 'Restart=always'
echo 'RestartSec=10'
echo ''
echo '[Install]'
echo 'WantedBy=multi-user.target'
} > /etc/systemd/system/vtund.service

systemctl enable vtund
systemctl start vtund
netstat -lntup4
