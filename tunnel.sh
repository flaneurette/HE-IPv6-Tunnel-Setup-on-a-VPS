#!/bin/sh
# Hurricane Electric IPv6 tunnel setup (SIT)

# NOTICE: Safety guard - manually comment this line to run:
exit 1

# HE tunnel server IPv4
HE_SERVER_IPV4="102.2.3.4"

# Your VPS public IPv4
YOUR_VPS_IPV4="202.2.3.4"

# Client IPv6 block address (from HE panel)
CLIENT_IPV6="2001:470:abcd:1234::2"

# Server IPv6 address (from HE panel)
SERVER_IPV6="2001:470:abcd:1234::1"

# Optional: access SSH from a random IPv6 address (very hard to guess)
# By default, this is commented out in the source code. See line ~97.
SSH_IPV6="2001:470:abcd:1234::1"

# Tunnel name.
TUN_IF="he-ipv6"

# Amount of subnets on client IPv6.
SUBNETS="64"

# Apache config files.
PORTS_CONF="/etc/apache2/ports.conf"
BACKUP_CONF="/etc/apache2/ports.conf.bak"

echo "----------------------------"
echo "Creating tunnel interface..."

ip tunnel del $TUN_IF 2>/dev/null
ip tunnel add $TUN_IF mode sit remote $HE_SERVER_IPV4 local $YOUR_VPS_IPV4 ttl 255

sleep 1

ip addr add $CLIENT_IPV6/64 dev $TUN_IF

sleep 1

ip link set $TUN_IF up

sleep 1

ip -6 route add ::/0 dev $TUN_IF

sleep 1

# Backup current config
cp $PORTS_CONF $BACKUP_CONF
echo "----------------------------"
echo "Backup saved to $BACKUP_CONF"

# Overwrite ports.conf
cat > $PORTS_CONF <<EOF
# Listen on all IPv4 addresses
Listen 0.0.0.0:80
Listen 0.0.0.0:443

# Listen on your IPv6 address
Listen [$CLIENT_IPV6]:80
Listen [$CLIENT_IPV6]:443
EOF

echo "----------------------------"
echo "ports.conf updated"
echo "----------------------------"

sleep 1

# Test Apache config syntax
apache2ctl configtest

sleep 1

# Reload Apache to apply changes
systemctl reload apache2
echo "----------------------------"
echo "Done. Apache reloaded."
echo "----------------------------"
echo "Sockets listening:"
ss -tuln | grep 80
echo "----------------------------"
echo "Adding ip6tables rules..."
echo "----------------------------"

# Allow established connections
ip6tables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow HTTP/HTTPS to HE address
ip6tables -A INPUT -p tcp -d $CLIENT_IPV6/$SUBNETS --dport 80 -j ACCEPT
ip6tables -A INPUT -p tcp -d $CLIENT_IPV6/$SUBNETS --dport 443 -j ACCEPT
# ip6tables -A INPUT -p tcp -d $SSH_IPV6 --dport 22 -j ACCEPT

apt install iptables-persistent
netfilter-persistent save

sleep 1

echo "Done"
echo "----------------------------"
echo "IPv6 routes:"
ip -6 route show
echo "----------------------------"
sleep 1

echo "Testing connectivity..."
echo "----------------------------"
ping6 -c 3 $SERVER_IPV6
ping6 -c 3 google.com
echo "----------------------------"
echo "Done. HE IPv6 tunnel should be up. If not, consult README or search online for error messages."
