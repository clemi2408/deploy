

# Setup Bridged Network

## Save config file

```bash
cat << EOF > /etc/netplan/00-snapd-config.yaml
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: false
      dhcp6: false

  bridges:
    br0:
      interfaces: [eth0]
      addresses: [192.168.2.1/24]
      gateway4: 192.168.2.254
      mtu: 1500
      nameservers:
        addresses: [192.168.2.254]
      dhcp4: no
      dhcp6: no
EOF
```

## Try settings

```bash
sudo netplan try
```

## Apply settings

```bash
sudo netplan apply
```