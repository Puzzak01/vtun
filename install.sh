#!/bin/bash

apt update
apt install -y arping bridge-utils dnsmasq iptables net-tools inetutils-inetd

FILE="/etc/network/interfaces"
LINE="source /etc/network/interfaces.d/*"

if [ -f "$FILE" ] && ! grep -Fxq "$LINE" "$FILE"; then
    echo "" >> "$FILE"
    echo "$LINE" >> "$FILE"
fi

{
echo 'auto br-ipcam'
echo 'iface br-ipcam inet static'
echo '    address 44.188.200.1'
echo '    netmask 255.255.255.0'
echo '    bridge_ports zero'
echo '    up mkdir -p /var/lock/vtund /var/log/vtund'
} > /etc/network/interfaces.d/br-ipcam

ifup br-ipcam

{
echo 'port=0'
echo ''
echo 'conf-dir=/etc/dnsmasq.d/,*.conf'
echo ''
echo 'domain-needed'
echo 'bogus-priv'
echo 'filterwin2k'
echo ''
echo 'no-resolv'
echo 'no-poll'
echo ''
echo 'server=77.88.8.8'
echo 'server=8.8.4.4'
echo ''
echo 'dhcp-option=option:ntp-server,77.88.8.8'
echo 'dhcp-option=option:dns-server,8.8.4.4,8.8.8.8'
echo ''
echo 'dhcp-option=121,44.188.200.0/24,44.188.200.1'
echo ''
echo 'dhcp-leasefile=/var/lib/misc/dnsmasq.leases'
echo 'log-facility=/var/log/dnsmasq.log'
echo 'log-queries'
echo 'log-dhcp'
echo ''
echo 'dhcp-authoritative'
echo 'cache-size=150'
echo 'no-negcache'
echo ''
echo 'conf-file=/etc/vtund.dhcp'
echo ''
echo 'interface=br-ipcam'
echo 'listen-address=44.188.200.1'
echo 'dhcp-range=44.188.200.2,44.188.200.254,255.255.255.0,infinite'
} > /etc/dnsmasq.conf

{
echo '5000    stream  tcp     nowait  root    /usr/local/bin/vtund vtund -i -f /etc/vtund.conf'
} > /etc/inetd.conf

systemctl restart dnsmasq
systemctl restart inetutils-inetd

sysctl -w net.ipv4.ip_forward=1; sysctl -p /etc/sysctl.conf

touch /etc/vtund.dhcp

wget -O /usr/local/bin/vtund https://github.com/Puzzak01/vtun/raw/refs/heads/main/vtund
chmod +x /usr/local/bin/vtund

{
echo 'options {'
echo '  port 5000;'
echo '  syslog cron;'
echo '  timeout 60;'
echo '  ip /bin/ip;'
echo '}'
echo 'default {'
echo '  type tun;'
echo '  proto tcp;'
echo '  persist yes;'
echo '  keepalive 10:5;'
echo '  timeout 60;'
echo '  compress no;'
echo '  encrypt no;'
echo '  stat no;'
echo '  speed 512:512;'
echo '  multi killold;'
echo '}'
echo '#'
} > /etc/vtund.conf

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
systemctl enable dnsmasq

systemctl restart dnsmasq; sleep 1; systemctl --no-pager status dnsmasq
systemctl restart vtund ; systemctl status vtund ; netstat -lntup4
