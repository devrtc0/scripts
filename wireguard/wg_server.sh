#!/usr/bin/env sh

# https://www.digitalocean.com/community/tutorials/how-to-set-up-wireguard-on-ubuntu-22-04#step-3-creating-a-wireguard-server-configuration
# https://tokmakov.msk.ru/blog/item/535

# 1. SERVER
# install
yay -Sy wireguard-tools --noconfirm --needed

# private key
sudo mkdir -p /etc/wireguard
wg genkey | sudo tee /etc/wireguard/private.key
sudo chmod go= /etc/wireguard/private.key

# public key
sudo cat /etc/wireguard/private.key | wg pubkey | sudo tee /etc/wireguard/public.key

# forwarding
sudo mkdir -p /etc/sysctl.d
printf 'net.ipv4.ip_forward=1\n' | sudo tee /etc/sysctl.d/00-forwarding.conf
sudo sysctl -p

set -a
WG_ADDRESS='10.8.0.1/24'
WG_NETWORK='10.8.0.0/24'
WG_IFACE='enp0s8'
WG_PRIVATE_KEY=$(sudo cat /etc/wireguard/private.key | tr -d '\n')
set +a

cat <<EOF | envsubst "${WG_ADDRESS} ${WG_NETWORK} ${WG_IFACE} ${WG_PRIVATE_KEY}" > /etc/wireguard/wg0.conf
[Interface]
Address = $WG_ADDRESS
PostUp = iptables -P FORWARD DROP
PostUp = iptables -A FORWARD -i %i -o %i -s $WG_NETWORK -d $WG_NETWORK -j ACCEPT
PostUp = iptables -A FORWARD -i %i -o $WG_IFACE -s $WG_NETWORK -j ACCEPT
PostUp = iptables -A FORWARD -i $WG_IFACE -o %i -d $WG_NETWORK -j ACCEPT
PostUp = iptables -t nat -A POSTROUTING -o $WG_IFACE -j MASQUERADE
PostDown = iptables -P FORWARD ACCEPT
PostDown = iptables -D FORWARD -i %i -o %i -s $WG_NETWORK -d $WG_NETWORK -j ACCEPT
PostDown = iptables -D FORWARD -i %i -o $WG_IFACE -s $WG_NETWORK -j ACCEPT
PostDown = iptables -D FORWARD -i $WG_IFACE -o %i -d $WG_NETWORK -j ACCEPT
PostDown = iptables -t nat -D POSTROUTING -o $WG_IFACE -j MASQUERADE
ListenPort = 51820
PrivateKey = $WG_PRIVATE_KEY

[Peer]
PublicKey = <CLIENT PUBLIC KEY>
AllowedIPs = 10.8.0.2/32

EOF

# sudo systemctl start wg-quick@wg0.service
# run
sudo wg-quick up wg0
