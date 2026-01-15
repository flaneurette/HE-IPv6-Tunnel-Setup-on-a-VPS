# HE IPv6 Tunnel Setup on a VPS - Summary

## 1. Prerequisites

* VPS with IPv4 access
* HE.net account with a free IPv6 tunnel (client /48 or /64)
* Root access to the VPS
* Apache installed (or other web server)

---

## 2. Check kernel support for SIT tunnels

```bash
lsmod | grep sit
```

Expected output:

```
sit
```

If SIT is not loaded:

```bash
modprobe sit
```

* Needed for IPv6-over-IPv4 tunnels

---

## 3. Create HE tunnel interface (if not already created)

```bash
ip tunnel add he-ipv6 mode sit remote <HE_SERVER_IP> local <YOUR_VPS_IPV4> ttl 255
```

---

## 4. Assign IPv6 address to the tunnel

```bash
ip addr add <CLIENT_IPV6>/64 dev he-ipv6
ip link set he-ipv6 up
```

* Example:

```bash
ip addr add <CLIENT_IPV6>/64 dev he-ipv6
ip link set he-ipv6 up
```

---

## 5. Add IPv6 default route via the tunnel

```bash
ip -6 route add ::/0 dev he-ipv6
```

* Check current IPv6 route:

```bash
ip -6 route show
```

* Should include:

```
::/0 dev he-ipv6
<CLIENT_IPV6>/64 dev he-ipv6
```

---

## 6. Test IPv6 connectivity

From the VPS:

```bash
ping6 google.com             # ping an external IPv6 host
```

https://tools.keycdn.com/ipv6-ping

Confirms tunnel works

---

## 7. Configure Apache to listen on IPv6

Edit `/etc/apache2/ports.conf`:

```apache
Listen 0.0.0.0:80
Listen 0.0.0.0:443
Listen <CLIENT_IPV6>:80
Listen <CLIENT_IPV6>:443
```

* Using the specific IPv6 address avoids `[::]:80` bind issues
* Test Apache configuration:

```bash
apachectl configtest
```

* Restart Apache:

```bash
systemctl restart apache2
```

* Check listening sockets:

```bash
ss -tuln | grep 80
```

Expected:

```
0.0.0.0:80
[<CLIENT_IPV6>]:80
```

---

## 8. Configure IPv6 firewall (if using iptables)

```bash
# Allow HTTP/HTTPS to HE address
ip6tables -A INPUT -p tcp -d <CLIENT_IPV6> --dport 80 -j ACCEPT
ip6tables -A INPUT -p tcp -d <CLIENT_IPV6> --dport 443 -j ACCEPT
# Allow established connections
ip6tables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
```

* Save rules for reboot:

```bash
apt install iptables-persistent
netfilter-persistent save
```

---

## 9. Test from external networks

* From IPv6-enabled hosts (not all home ISPs!):

```bash
ping6 <CLIENT_IPV6>
curl -6 http://[<CLIENT_IPV6>]/
```

* If it fails from home: your ISP likely does not provide IPv6 connectivity
* Tools like KeyCDN can confirm IPv6 reachability globally

---

## 10. Notes / caveats

* HE tunnel may be unreachable from some ISPs - only IPv6-enabled networks can access
* Apache must bind to a specific IPv6 address on tunnels to avoid `[::]:80` errors
* SIT tunnels are kernel-level - check `lsmod` and `ip tunnel show` if issues occur
* Multiple HE tunnels can be created if your VPS allows it - useful for testing different /48 addresses

---

