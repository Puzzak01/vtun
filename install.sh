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
netstat -lntup4
