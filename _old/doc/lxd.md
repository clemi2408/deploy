# LXD 

## Update Sources

```bash
apt update
```

## Install SNAP

```bash
apt install snapd
```

## Install LXD SNAP

```bash
snap install lxd
```

## Update LXD SNAP to Version
```bash
/usr/bin/snap refresh lxd --channel=4.24/stable
```

## Remove old config

```bash
sudo lxc profile device remove default root
```

```bash
sudo lxc profile device remove default eth0
```

```bash
sudo lxc storage delete local
```

```bash
sudo lxc config unset core.https_address
```

## Preseed Cluster

```bash
cat <<EOF | lxd init --preseed
config:
  core.https_address: "192.168.2.1:8443"
  core.trust_password: clemens
networks: []
storage_pools:
- config:
    size: 20GB
  description: ""
  name: local
  driver: btrfs
profiles:
- config: {}
  description: ""
  devices:
    eth0:
      name: eth0
      nictype: bridged
      parent: br0
      type: nic
    root:
      path: /
      pool: local
      type: disk
  name: default
cluster:
  server_name: host01
  enabled: true
  member_config: []
  cluster_address: ""
  cluster_certificate: ""
  server_address: ""
  cluster_password: ""
  cluster_certificate_path: ""
EOF
```

## Create Storage pool

```bash
lxc storage create local dir
```

## Disable Secure boot due to 64 bit Arm

```bash
sudo lxc profile set default security.secureboot false
```

## Launch LXD Test VM

```bash
sudo lxc launch images:ubuntu/20.04/cloud testvm
```

```bash
sudo lxc list
```

```bash
sudo lxc exec testvm bash
```

```bash
sudo lxc stop testvm
```

```bash
sudo lxc delte testvm
```

```bash
sudo lxc list
```

```bash
sudo lxc image list
```

```bash
sudo lxc image delete xxxxxxxx
```