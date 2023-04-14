# Manual setup MaaS VM

## Setup VM

### Register LXC VM Profile

```bash
lxc profile create maas01_bru-profile
```

### Set LXC VM Profile

```bash
cat <<EOF | lxc profile edit maas01_bru-profile
config:
  security.secureboot: "false"
  user.network-config: |
    version: 2
    ethernets:
      eth0:
        dhcp4: no
        dhcp6: no
        optional: true
        addresses: [192.168.2.100/24]
        gateway4: 192.168.2.254
        nameservers:
          addresses: [192.168.2.254]
  user.user-data: |
    #cloud-config
    hostname: maas01
    fqdn: maas01.maas.bru.int.cleem.de    

    locale: "de_DE.UTF-8"
    timezone: Europe/Berlin
    keyboard: {layout: de, toggle: null, variant: ''}    

    chpasswd: { expire: false }
    ssh_pwauth: false
    password: secret    

    package_update: true
    package_upgrade: true
    packages:
      - openssh-server
      - snapd    

    final_message: "Cloud init is done.!"    

    users:
      - default
      - name: ubuntu
        ssh-authorized-keys:
          - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDmlRbfaE4y7z1DcLi0ViI/qDyulpy5aSyJPyS/dUU0ZvUg5Wq/pK734Kv9T026jUysSPTk9uEFc6ZRjFyBcvAmBKr3pepRE3NIEMVaTf2eJ/E6Ipm7Z1yVDM30u7fNxP6kyup5AMWShYe52HQKZOhpV1+KFuE6RA4GJpt17nmfTF/jXf9qrbHY3CuufvE1wWsFhnQZKH2K2hi4OpytAUjdXJbHgjuzd6gkzKRy3DXS/wddU3rgKS9uja9HKVfuBB3DRixi8Y/hB0Ve3dw8WcFVxGhjE1zZmWJZQ93VBxQUBubMW2j5/I71hhbgE+dZ5jXhqK3ppz1HYW6FIdxt0IyCC/bUoPF9FV4MNtsNosz9lCjZcNVbAv7u+0nNKyL6AykptDekzL/mbuLy16EC7IiX6gm8Dud9VX9sRYflFM7kglVxdaFKcngIjnnumpk9WI8+4GY4ASgszAQk/dzl6JdiEtypHs2cyTzF0y29RTJQcHBiMMt0byJLFE4AutIp7jU= clemens@cknb.local
        sudo: ['ALL=(ALL) NOPASSWD:ALL']
        groups: sudo
        shell: /bin/bash    

    ntp:
      servers: ['ptbtime1.ptb.de', 'ptbtime2.ptb.de', 'ptbtime3.ptb.de']    

    write_files:
      - path: /etc/sysctl.d/10-disable-ipv6.conf
        permissions: 0644
        owner: root
        content: |
          net.ipv6.conf.all.disable_ipv6=1
          net.ipv6.conf.default.disable_ipv6=1
          net.ipv6.conf.lo.disable_ipv6=1
      - path: /opt/cleem/seed/init.sh
        permissions: 0755
        owner: root
        content: |
          #!/bin/bash
          echo ===== START: INITCMD =====
          CLOUD_NAME=maas01_bru
          CLOUD_USER=admin  
          
          echo "INFO: $CLOUD_NAME - Getting API Key for $CLOUD_USER"
          
          API_KEY=$(maas apikey --username $CLOUD_USER)
          CONFIG_FILE="$CLOUD_NAME-cloud.yaml"
          CREDENTIAL_FILE="$CLOUD_NAME-creds.yaml"  
          
          echo "INFO: $CLOUD_NAME - Creating juju cloud config $CONFIG_FILE"  
          
          tee "$CONFIG_FILE" > /dev/null <<EOF
          clouds:
            $CLOUD_NAME:
              type: maas
              auth-types: [oauth1]
              endpoint: $MAAS_URL
          EOF  

          echo "INFO: $CLOUD_NAME - Creating juju cloud credentials $CREDENTIAL_FILE"  

          tee "$CREDENTIAL_FILE" > /dev/null <<EOF
          credentials:
            $CLOUD_NAME:
              anyuser:
                auth-type: oauth1
                maas-oauth: $API_KEY
          EOF  

          echo "INFO: $CLOUD_NAME - Adding juju cloud config"
          juju add-cloud --client -f $CONFIG_FILE $CLOUD_NAME  

          echo "INFO: $CLOUD_NAME - Adding juju cloud credentials"
          juju add-credential --client -f $CREDENTIAL_FILE $CLOUD_NAME

          rm /etc/systemd/system/firstboot.service
          #rm -r /opt/cleem/seed
          echo ===== END: INITCMD =====
          reboot

      - path: /etc/systemd/system/firstboot.service
        permissions: 0644
        owner: root
        content: |
          [Unit]
          Description=One time boot script
          [Service]
          Type=simple
          ExecStart=/opt/cleem/seed/init.sh
          [Install]
          WantedBy=multi-user.target 
    bootcmd:
      - [ sh, -xc, "echo ===== START: BOOTCMD =====" ]
      - [ mkdir, -p, /mnt/usb01 ]
      - [ mkdir, -p, /opt/cleem/seed ]
      - [ sh, -xc, "echo ===== END: BOOTCMD =====" ]    
      
    runcmd:
      - [ sh, -xc, "echo ===== START: RUNCMD =====" ]
      - [ /usr/bin/snap, install, maas ]
      - [ /usr/bin/snap, install, maas-test-db]
      - [ /snap/bin/maas, init, region+rack, --maas-url, http://192.168.2.100:5240/MAAS, --database-uri, maas-test-db:///]
      - [ /snap/bin/maas, createadmin, --username, admin, --password, admin, --email, admin@maas.bru.int.cleem.de, --ssh-import, '']
      - [ /usr/bin/snap, install, juju, --classic ]
      - [ systemctl, daemon-reload ]
      - [ systemctl, enable, firstboot.service ]
      - [ sh, -xc, "echo ===== END: RUNCMD =====" ]

    power_state:
      mode: reboot    

description: maas01 LXD profile
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
name: maas01
used_by: [] 
EOF
```

### Launch Container with Profile

```bash
sudo lxc launch images:ubuntu/20.04/cloud maas01 -p maas01_bru-profile
```
### Enter Container 


```bash
sudo lxc list
```

```bash
sudo lxc exec maas01 bash
```

### Show Logs

```bash
tail -fn 20 /var/snap/maas/common/log/maas.log
```

### Remove MaaS

```bash
sudo lxc exec maas01 bash
```

```bash
snap remove maas-test-db  --purge
```

```bash
snap remove maas --purge
```

## Configure MaaS VM (WebUI)
http://192.168.2.100:5240/MAAS
-> set dns
-> import images
-> add public key
-> disable statistics
-> storage and erase
-> ntp
-> network discovery
-> dhcp snippets (static)
-> dhcp server
-> host availability zone 
-> host resource pool 

## Create MaaS Test-VM
```bash
maas admin boot-source-selections \
create 1 os="ubuntu" release="forcal" arches="arm64" \
subarches="*" labels="*"
```
