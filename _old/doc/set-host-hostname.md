# Configure Hostname

## hostname File
```bash
cat << EOF > /etc/hostname
host01
EOF
```

## hosts File

```bash
cat << EOF > /etc/hosts
127.0.0.1       localhost
127.0.1.1       host01.lxd.bru.int.cleem.de lxd01
EOF
```