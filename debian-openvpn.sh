#!/bin/bash

# Bu script yalnızca Debian için optimize edilmiştir.
# Debian 11 ve üstü gereklidir.

if [[ $(readlink /proc/$$/exe) != *"/bash" ]]; then
    echo 'Bu script yalnızca "bash" ile çalıştırılabilir.'
    exit 1
fi

if [[ $(id -u) -ne 0 ]]; then
    echo 'Bu script yalnızca root kullanıcı olarak çalıştırılabilir.'
    exit 1
fi

if [[ ! -e /etc/debian_version ]]; then
    echo 'Bu script yalnızca Debian sistemleri için tasarlanmıştır.'
    exit 1
fi

if [[ ! -e /dev/net/tun ]] || ! (exec 7<>/dev/net/tun) 2>/dev/null; then
    echo 'TUN cihazı mevcut değil. Devam etmeden önce etkinleştirilmelidir.'
    exit 1
fi

os_version=$(grep -oE '^[0-9]+' /etc/debian_version | head -1)
if [[ "$os_version" -lt 11 ]]; then
    echo 'Debian 11 veya üstü gereklidir.'
    exit 1
fi

# Gerekli paketlerin kurulumu
apt-get update
apt-get install -y --no-install-recommends openvpn openssl ca-certificates iptables

# Easy-RSA kurulumu ve yapılandırması
easy_rsa_url='https://github.com/OpenVPN/easy-rsa/releases/download/v3.2.1/EasyRSA-3.2.1.tgz'
mkdir -p /etc/openvpn/server/easy-rsa/
{ wget -qO- "$easy_rsa_url" 2>/dev/null || curl -sL "$easy_rsa_url" ; } | tar xz -C /etc/openvpn/server/easy-rsa/ --strip-components 1
chown -R root:root /etc/openvpn/server/easy-rsa/
cd /etc/openvpn/server/easy-rsa/

./easyrsa --batch init-pki
./easyrsa --batch build-ca nopass
./easyrsa --batch build-server-full server nopass
./easyrsa --batch build-client-full client nopass
./easyrsa --batch gen-crl

# Gerekli dosyaların taşınması
cp pki/ca.crt pki/private/ca.key pki/issued/server.crt pki/private/server.key pki/crl.pem /etc/openvpn/server/
chmod o+x /etc/openvpn/server/
openvpn --genkey secret /etc/openvpn/server/tc.key

echo '-----BEGIN DH PARAMETERS-----
MIIBCAKCAQEA//////////+t+FRYortKmq/cViAnPTzx2LnFg84tNpWp4TZBFGQz
+8yTnc4kmz75fS/jY2MMddj2gbICrsRhetPfHtXV/WVhJDP1H18GbtCFY2VVPe0a
87VXE15/V8k1mE8McODmi3fipona8+/och3xWKE2rec1MKzKT0g6eXq8CrGCsyT7
YdEIqUuyyOP7uWrat2DX9GgdT0Kj3jlN9K5W7edjcrsZCwenyO4KbXCeAvzhzffi
7MA0BM0oNC9hkXL+nOmFg/+OTxIy7vKBg8P+OxtMb61zO7X8vC7CIAXFjvGDfRaD
ssbzSibBsu/6iGtCOGEoXJf//////////wIBAg==
-----END DH PARAMETERS-----' > /etc/openvpn/server/dh.pem

# OpenVPN sunucu yapılandırması
echo "local 0.0.0.0
port 1194
proto udp
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh.pem
auth SHA512
tls-crypt tc.key
topology subnet
server 10.8.0.0 255.255.255.0
push \"redirect-gateway def1 bypass-dhcp\"
push \"dhcp-option DNS 8.8.8.8\"
push \"dhcp-option DNS 8.8.4.4\"
keepalive 10 120
persist-key
persist-tun
status openvpn-status.log
log-append /var/log/openvpn.log
verb 3
crl-verify crl.pem" > /etc/openvpn/server/server.conf

# IP yönlendirme ve iptables kuralları
echo 1 > /proc/sys/net/ipv4/ip_forward
echo 'net.ipv4.ip_forward=1' > /etc/sysctl.d/99-openvpn.conf
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o $(ip route | grep default | awk '{print $5}') -j MASQUERADE

# OpenVPN servisini etkinleştirme
systemctl enable --now openvpn-server@server.service

# Kullanıcı yapılandırma dosyasının oluşturulması
cat > ~/client.ovpn <<EOL
client
dev tun
proto udp
remote YOUR_SERVER_IP 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
auth SHA512
tls-crypt tc.key
verb 3
<ca>
$(cat /etc/openvpn/server/ca.crt)
</ca>
<cert>
$(sed -ne '/BEGIN CERTIFICATE/,$ p' /etc/openvpn/server/easy-rsa/pki/issued/client.crt)
</cert>
<key>
$(cat /etc/openvpn/server/easy-rsa/pki/private/client.key)
</key>
<tls-crypt>
$(cat /etc/openvpn/server/tc.key)
</tls-crypt>
EOL

echo "OpenVPN kurulumu tamamlandı. Kullanıcı yapılandırma dosyası: ~/client.ovpn"
