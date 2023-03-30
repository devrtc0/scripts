#!/usr/bin/env sh

# https://www.digitalocean.com/community/tutorials/how-to-set-up-wireguard-on-ubuntu-22-04#step-3-creating-a-wireguard-server-configuration
# https://tokmakov.msk.ru/blog/item/535

# 2. CLIENT
# install
yay -Sy wireguard-tools --noconfirm --needed

# private key
sudo mkdir -p /etc/wireguard
wg genkey | sudo tee /etc/wireguard/private.key
sudo chmod go= /etc/wireguard/private.key

# public key
sudo cat /etc/wireguard/private.key | wg pubkey | sudo tee /etc/wireguard/public.key

set -a
WG_ADDRESS='10.8.0.2/24'
WG_ALLOWED_IPS='10.8.0.1/32, 10.230.192.77/32'
WG_ENDPOINT='1.1.1.1:51820'
WG_PRIVATE_KEY=$(sudo cat /etc/wireguard/private.key | tr -d '\n')
set +a

cat <<EOF | envsubst "${WG_ADDRESS} ${WG_ALLOWED_IPS} ${WG_ENDPOINT} ${WG_PRIVATE_KEY}" > /etc/wireguard/wg0.conf
[Interface]
PrivateKey = $WG_PRIVATE_KEY
Address = $WG_ADDRESS

[Peer]
PublicKey = <SERVER PUBLIC KEY>
AllowedIPs = $WG_ALLOWED_IPS
Endpoint = $WG_ENDPOINT

EOF

# run
sudo wg-quick up wg0
