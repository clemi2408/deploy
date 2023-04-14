# Disable IPv6

## Create sysctl file

```bash
cat << EOF > /etc/sysctl.d/15-disable-ipv6.conf
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.lo.disable_ipv6=1
EOF
```

## Reload Settings

```bash
/etc/init.d/procps restart
```

## Check Settings

```bash
ip a
```