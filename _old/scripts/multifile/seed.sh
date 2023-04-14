#!/bin/bash

####======= Global parameters
SEED_DIR="/opt/cleem/seed"

####======= LXD parameters
LXD_PORT=8443
LXD_SECRET="secret"
LXD_PROJECT_NAME="local-lxd"

####======= maaspower parameters
MAASPOWER_PORT=5000
MAASPOWER_USER="admin"
MAASPOWER_PASSWORD="admin"
MAASPOWER_USB_ID="2-2"

####======= MaaS parameters
MAAS_ADMIN_USER="admin"
MAAS_ADMIN_PASSWORD="admin"
MAAS_SSH_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDmlRbfaE4y7z1DcLi0ViI/qDyulpy5aSyJPyS/dUU0ZvUg5Wq/pK734Kv9T026jUysSPTk9uEFc6ZRjFyBcvAmBKr3pepRE3NIEMVaTf2eJ/E6Ipm7Z1yVDM30u7fNxP6kyup5AMWShYe52HQKZOhpV1+KFuE6RA4GJpt17nmfTF/jXf9qrbHY3CuufvE1wWsFhnQZKH2K2hi4OpytAUjdXJbHgjuzd6gkzKRy3DXS/wddU3rgKS9uja9HKVfuBB3DRixi8Y/hB0Ve3dw8WcFVxGhjE1zZmWJZQ93VBxQUBubMW2j5/I71hhbgE+dZ5jXhqK3ppz1HYW6FIdxt0IyCC/bUoPF9FV4MNtsNosz9lCjZcNVbAv7u+0nNKyL6AykptDekzL/mbuLy16EC7IiX6gm8Dud9VX9sRYflFM7kglVxdaFKcngIjnnumpk9WI8+4GY4ASgszAQk/dzl6JdiEtypHs2cyTzF0y29RTJQcHBiMMt0byJLFE4AutIp7jU= clemens@cknb.local"

MAAS_DHCP_START="10.0.0.200"
MAAS_DHCP_END="10.0.0.210"
MAAS_DNS_IP="10.0.0.254"
MAAS_GATEWAY_IP="10.0.0.254"
MAAS_NTP_IP="10.0.0.254"

####======= Juju parameters
JUJU_LOCAL_USER="ubuntu"
JUJU_USER="admin"
JUJU_PASSWORD="admin"

####======= Runtime parameters
INTERFACE=$(ip route | grep default | cut -d ' ' -f 5)
IP=$(ip -4 addr show dev $INTERFACE | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

TMP_DIR="/tmp"
REPO="https://raw.githubusercontent.com/clemi2408/deploy/main"
LIBS=("commons.sh" "ipv6.sh" "rsyslog.sh" "lxd.sh" "maaspower.sh" "maas.sh" "juju.sh")

####=========================================================================
downloadLibs(){

   for lib in ${LIBS[@]}; do

        
      local url="$REPO/$lib"
      local target="$TMP_DIR/lib/$lib"

      echo "INFO: Downloading lib $lib via $url to $target"
      curl -s -o $target $url
      source "$target"

    done

}

####=========================================================================
if [ "$1" = "install" ]; then

   downloadLibs
   commons_createFolder "$SEED_DIR"
   ipv6_disable
   rsyslog_enableRemote "$SEED_DIR"
   lxd_install "$SEED_DIR" "$IP" "$LXD_PORT" "$INTERFACE" "$LXD_PROJECT_NAME" "$LXD_SECRET"
   maaspower_install "$SEED_DIR" "$IP" "$MAASPOWER_PORT" "$MAASPOWER_USER" "$MAASPOWER_PASSWORD" "$MAASPOWER_USB_ID"
   maas_install "$SEED_DIR" "$IP" "$MAAS_ADMIN_USER" "$MAAS_ADMIN_PASSWORD" "$IP" "$MAAS_GATEWAY_IP" "$MAAS_DNS_IP" "$MAAS_NTP_IP" "$IP" "$LXD_PORT" "$LXD_PROJECT_NAME" "$LXD_SECRET" "$MAAS_SSH_KEY" "$MAAS_DHCP_START" "$MAAS_DHCP_END"
   juju_installClient "$JUJU_LOCAL_USER" "$MAAS_ADMIN_USER"

elif [ "$1" = "remove" ]; then

   downloadLibs
   juju_removeClient "$JUJU_LOCAL_USER"
   maas_remove "$SEED_DIR"
   maaspower_remove "$SEED_DIR"
   lxd_remove "$SEED_DIR"
   rsyslog_disableRemote "$SEED_DIR"
   ipv6_enable
   commons_deleteFolder "$SEED_DIR"
   apt-get -y autoremove

elif [ "$1" = "installController" ]; then   

   downloadLibs
   juju_installController "$JUJU_LOCAL_USER" "$LXD_PROJECT_NAME" "$JUJU_USER" "$JUJU_PASSWORD"

elif [ "$1" = "removeController" ]; then   

   downloadLibs
   juju_removeController "$JUJU_LOCAL_USER"


else
   echo "try install, remove or installController, removeController"
fi
