#!/bin/bash

####======= Global parameters
SEEDDIR="/opt/cleem/seednew"
REPO="https://raw.githubusercontent.com/clemi2408/deploy/main"

####======= IPv6 settings
IPv6_SYSCTL_FILE=/etc/sysctl.d/10-disable-ipv6.conf

####======= rsyslog
RSYSLOG_CONFIG=/etc/rsyslog.conf
RSYSLOG_CONFIG_BACKUP=/etc/rsyslog.bak

####======= maaspower settings
MAASPOWER_PORT=5000
MAASPOWER_USER=admin
MAASPOWER_PASSWORD=admin
MAASPOWER_SERVICE_NAME=maaspower.service
MAASPOWER_SERVICE_FILE=/etc/systemd/system/$MAASPOWER_SERVICE_NAME
MAASPOWER_DIR=$SEEDDIR/maaspower
MAASPOWER_CONFIG=$MAASPOWER_DIR/maaspower.cfg
MAASPOWER_USB_ID="2-2"

####======= MaaS settings
MAAS_ADMIN_USER=admin
MAAS_ADMIN_PASSWORD=admin
MAAS_ADMIN_EMAIL=admin@maas.srv.bru
MAAS_DIR=$SEEDDIR/maas
MAAS_APIKEY_FILE=$MAAS_DIR/apikey
MAAS_DNS=10.0.0.254
MAAS_GATEWAY=10.0.0.254
MAAS_NTP=10.0.0.254
MAAS_NODE_DEPLOYMENT_TIMEOUT_IN_MIN=90
MAAS_DHCP_START="10.0.0.100"
MAAS_DHCP_END="10.0.0.200"
MAAS_DHCP_RESERVED=("10.0.0.254")
MAAS_SPACE=srv.bru-space
MAAS_SSH_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDmlRbfaE4y7z1DcLi0ViI/qDyulpy5aSyJPyS/dUU0ZvUg5Wq/pK734Kv9T026jUysSPTk9uEFc6ZRjFyBcvAmBKr3pepRE3NIEMVaTf2eJ/E6Ipm7Z1yVDM30u7fNxP6kyup5AMWShYe52HQKZOhpV1+KFuE6RA4GJpt17nmfTF/jXf9qrbHY3CuufvE1wWsFhnQZKH2K2hi4OpytAUjdXJbHgjuzd6gkzKRy3DXS/wddU3rgKS9uja9HKVfuBB3DRixi8Y/hB0Ve3dw8WcFVxGhjE1zZmWJZQ93VBxQUBubMW2j5/I71hhbgE+dZ5jXhqK3ppz1HYW6FIdxt0IyCC/bUoPF9FV4MNtsNosz9lCjZcNVbAv7u+0nNKyL6AykptDekzL/mbuLy16EC7IiX6gm8Dud9VX9sRYflFM7kglVxdaFKcngIjnnumpk9WI8+4GY4ASgszAQk/dzl6JdiEtypHs2cyTzF0y29RTJQcHBiMMt0byJLFE4AutIp7jU= clemens@cknb.local"
MAAS_STORAGE_LAYOUT="lvm"
MAAS_OS="ubuntu"
MAAS_OS_RELEASE="jammy"
MAAS_OS_ARCHES=("arm64" "amd64")
MAAS_LOCAL_LXD_NAME=local-lxd
MAAS_LOCAL_LXD_POOL=$MAAS_LOCAL_LXD_NAME-pool
MAAS_LOCAL_LXD_ZONE=$MAAS_LOCAL_LXD_NAME-zone

####======= lxd settings
LXD_DIR=$SEEDDIR/lxd
LXD_SEED_FILE=$LXD_DIR/lxd-seed.yml
LXD_PORT=8443
LXD_SECRET="secret"

####======= juju settings
JUJU_VERSION="2.9"
JUJU_USER="ubuntu"
JUJU_DIR="/home/$JUJU_USER/juju"
JUJU_CLOUD_YML=$JUJU_DIR/cloud.yaml
JUJU_CRED_YML=$JUJU_DIR/cred.yaml
JUJU_CRED_FOLDER="/home/$JUJU_USER/.local/share"
JUJU_CLOUD_NAME="maas-cloud"

####=========================================================================
INTERFACE=$(ip route | grep default | cut -d ' ' -f 5)
IP=$(ip -4 addr show dev $INTERFACE | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
####=========================================================================

deleteFolder(){

    local dir="$1"

    if [[ ! -e $dir ]]; then
        echo "WARN: Unable to delete directory $dir " 1>&2
    elif [[ -d $dir ]]; then
        echo "INFO: Deleting directory $dir" 1>&2
        rm -r $dir
    fi
}

deleteFile(){

    local file="$1"

    if [[ ! -e $file ]]; then
        echo "WARN: Unable to delete file $file " 1>&2
    elif [[ -f $file ]]; then
        echo "INFO: Deleting file $file" 1>&2
        rm $file
    fi
}

createFolder(){

    local dir="$1"

    if [[ ! -e $dir ]]; then
        echo "INFO: Creating $dir " 1>&2
        mkdir -p $dir
    elif [[ -d $dir ]]; then
        echo "WARN: $dir already exists" 1>&2
    fi
}

####= IPv6 ==================================================================

disableIpv6(){
    #Disabling IPv6
    curl -o $IPv6_SYSCTL_FILE $REPO/10-disable-ipv6.conf
}

enableIpv6(){
        
    deleteFile $IPv6_SYSCTL_FILE
}


installRsyslog(){

    echo "INFO: Installing rsyslog"
    apt-get -y install rsyslog

    echo "INFO: Backup rsyslog config $RSYSLOG_CONFIG to $RSYSLOG_CONFIG_BACKUP"
    cp $RSYSLOG_CONFIG $RSYSLOG_CONFIG_BACKUP

    echo "INFO: Enabling rsyslog tcp and udp"
    sed -i '/module(load="imudp")/s/^#//g' $RSYSLOG_CONFIG
    sed -i '/input(type="imudp" port="514")/s/^#//g' $RSYSLOG_CONFIG
    sed -i '/module(load="imtcp")/s/^#//g' $RSYSLOG_CONFIG
    sed -i '/input(type="imtcp" port="514")/s/^#//g' $RSYSLOG_CONFIG

    echo "INFO: Setting custom log template"
    cat >> $RSYSLOG_CONFIG << EOF

#Custom template to generate the log filename dynamically based on the client's IP address.
\$template RemInputLogs, "/var/log/remotelogs/%FROMHOST-IP%/%PROGRAMNAME%.log"
*.* ?RemInputLogs
EOF

    echo "INFO: Testing rsyslog config $RSYSLOG_CONFIG"
    rsyslogd -f $RSYSLOG_CONFIG -N1

    echo "INFO: Enabling rsyslog"
    systemctl enable rsyslog

    echo "INFO: Starting rsyslog"
    systemctl start rsyslog


}

removeRsyslog(){

    echo "INFO: Restoring rsyslog config backup $RSYSLOG_CONFIG_BACKUP"
    mv $RSYSLOG_CONFIG_BACKUP $RSYSLOG_CONFIG

    echo "INFO: Testing rsyslog config $RSYSLOG_CONFIG"
    rsyslogd -f $RSYSLOG_CONFIG -N1

    echo "INFO: Restarting rsyslog"
    systemctl restart rsyslog
    
}


####= lxd ===================================================================

installLxd(){

    echo "INFO: Installing lxd"

    snap install lxd

    createFolder $LXD_DIR

    echo "INFO: Creating lxd seed file $LXD_SEED_FILE"

    cat <<EOF >>$LXD_SEED_FILE
config:
  core.https_address: '$IP:$LXD_PORT'
  core.trust_password: $LXD_SECRET
networks: []
storage_pools:
- config: {}
  description: ""
  name: default
  driver: dir
profiles:
- config: {}
  description: ""
  devices:
    eth0:
      name: eth0
      nictype: bridged
      parent: $INTERFACE
      type: nic
    root:
      path: /
      pool: default
      type: disk
  name: default
projects: []
cluster: null
EOF

    echo "INFO: Seeding lxd $LXD_SEED_FILE"
    lxd init --preseed < "$LXD_SEED_FILE"

    echo "INFO: Creating lxd project $MAAS_LOCAL_LXD_NAME"
    lxc project create "$MAAS_LOCAL_LXD_NAME"

    echo "INFO: Switching to lxd project $MAAS_LOCAL_LXD_NAME"
    lxc project switch "$MAAS_LOCAL_LXD_NAME"

}

removeLxd(){
    
    echo "INFO: Removing lxd"

    snap remove --purge lxd

    deleteFolder $LXD_DIR

}

####= maaspower =============================================================

removeMaaspower(){

    echo "INFO: Removing maaspower"
    
    systemctl stop $MAASPOWER_SERVICE_NAME
    systemctl disable $MAASPOWER_SERVICE_NAME
    source $MAASPOWER_DIR/bin/activate
    python3 -m pip uninstall -y maaspower
    apt-get -y purge uhubctl
    apt-get -y purge python3.10-venv

    deleteFile $MAASPOWER_SERVICE_FILE
    deleteFolder $MAASPOWER_DIR
}

installMaaspower(){

    echo "INFO: Installing maaspower"

    createFolder $MAASPOWER_DIR

    echo "INFO: Installing uhubctl"
    apt-get -y install uhubctl

    echo "INFO: Installing python"
    apt-get -y install python3.10-venv

    echo "INFO: Creating virtual python environment $MAASPOWER_DIR"
    python3 -m venv $MAASPOWER_DIR

    echo "INFO: Activating virtual python environment $MAASPOWER_DIR"
    source $MAASPOWER_DIR/bin/activate

    echo "INFO: Upgrading pip"
    pip install --upgrade pip wheel

    echo "INFO: Installing maaspower"
    python3 -m pip install maaspower

    echo "INFO: Config for maaspower $MAASPOWER_CONFIG"

    cat <<EOF >>$MAASPOWER_CONFIG
# yaml-language-server: $schema=maaspower.schema.json
# NOTE: above relative path to a schema file from 'maaspower schema <filename>'

name: my maaspower control webhooks
ip_address: $IP
port: $MAASPOWER_PORT
username: $MAASPOWER_USER
password: $MAASPOWER_PASSWORD
devices:
  - type: CommandLine
    name: rpi1
    on: uhubctl -l $MAASPOWER_USB_ID -a 1 -p 1
    off: uhubctl -l $MAASPOWER_USB_ID -a 0 -p 1
    query: uhubctl -l $MAASPOWER_USB_ID -p 1
    query_on_regex: .*power$
    query_off_regex: .*off$
  - type: CommandLine
    name: rpi2
    on: uhubctl -l $MAASPOWER_USB_ID -a 1 -p 2
    off: uhubctl -l $MAASPOWER_USB_ID -a 0 -p 2
    query: uhubctl -l $MAASPOWER_USB_ID -p 2
    query_on_regex: .*power$
    query_off_regex: .*off$
  - type: CommandLine
    name: rpi3
    on: uhubctl -l $MAASPOWER_USB_ID -a 1 -p 3
    off: uhubctl -l $MAASPOWER_USB_ID -a 0 -p 3
    query: uhubctl -l $MAASPOWER_USB_ID -p 3
    query_on_regex: .*power$
    query_off_regex: .*off$
  - type: CommandLine
    name: rpi4
    on: uhubctl -l $MAASPOWER_USB_ID -a 1 -p 4
    off: uhubctl -l $MAASPOWER_USB_ID -a 0 -p 4
    query: uhubctl -l $MAASPOWER_USB_ID -p 4
    query_on_regex: .*power$
    query_off_regex: .*off$
EOF

    echo "INFO: Creating service for maaspower $MAASPOWER_SERVICE_FILE"

    cat <<EOF >>$MAASPOWER_SERVICE_FILE
[Unit]
Description=maaspower daemon
[Service]
ExecStart=$MAASPOWER_DIR/bin/maaspower run $MAASPOWER_CONFIG
[Install]
WantedBy=multi-user.target
EOF

    echo "INFO: Reloading services"
    systemctl daemon-reload

    echo "INFO: Enabling service $MAASPOWER_SERVICE_NAME"
    systemctl enable $MAASPOWER_SERVICE_NAME

    echo "INFO: Starting service $MAASPOWER_SERVICE_NAME"    
    systemctl start $MAASPOWER_SERVICE_NAME

}

####= maas ==================================================================

installMaas(){

    echo "INFO: Installing MaaS"

    local subnet=$(ip -o -f inet route |grep -e "link" | awk '{print $1}')
    local maasUrl=http://$IP:5240/MAAS

    #======= INSTALLING 
    createFolder $MAAS_DIR

    echo "INFO: Installing MaaS SNAP"
    snap install maas

    echo "INFO: Installing MaaS DB SNAP"
    snap install maas-test-db

    #======= INITIALIZING 
    echo "INFO: Initializing MaaS"
    maas init region+rack --database-uri maas-test-db:/// --maas-url $maasUrl
   
    #======= CREATING USER 
    echo "INFO: Creating user $MAAS_ADMIN_USER"
    maas createadmin --username $MAAS_ADMIN_USER --password $MAAS_ADMIN_PASSWORD --email $MAAS_ADMIN_EMAIL
    
    #======= CREATING APIKEY 
    echo "INFO: Getting api key for user $MAAS_ADMIN_USER"
    local apiKey=$(maas apikey --username $MAAS_ADMIN_USER)

    echo "INFO: Writing api key for user $MAAS_ADMIN_USER"
    echo $apiKey > $MAAS_APIKEY_FILE

    echo "INFO: Sleeping"
    sleep 30

    #======= LOGIN 
    echo "INFO: Login $MAAS_ADMIN_USER to $maasUrl"
    maas login $MAAS_ADMIN_USER $maasUrl "$apiKey"

    #======= STOP Image Import
    echo "INFO: Stopping image import"
    maas $MAAS_ADMIN_USER boot-resources stop-import

    #======= MAAS GENERAL CONFIG 
    echo "INFO: Completing intro"
    maas $MAAS_ADMIN_USER maas set-config name=completed_intro value=true

    echo "INFO: Disabling analytics"
    maas $MAAS_ADMIN_USER maas set-config name=enable_analytics value=false

    echo "INFO: Setting remote syslog"
    maas $MAAS_ADMIN_USER maas set-config name=remote_syslog value="$IP"

    echo "INFO: Setting upstream DNS $MAAS_DNS"
    maas $MAAS_ADMIN_USER maas set-config name=upstream_dns value=$MAAS_DNS

    echo "INFO: Setting provisioning timeout to $MAAS_NODE_DEPLOYMENT_TIMEOUT_IN_MIN minutes"
    maas $MAAS_ADMIN_USER maas set-config name=node_timeout value=$MAAS_NODE_DEPLOYMENT_TIMEOUT_IN_MIN

    echo "INFO: Enabling HTTP proxy"
    maas $MAAS_ADMIN_USER maas set-config name=enable_http_proxy value=true

    echo "INFO: Setting default storage layout to $MAAS_STORAGE_LAYOUT"
    maas $MAAS_ADMIN_USER maas set-config name=default_storage_layout value=$MAAS_STORAGE_LAYOUT

    echo "INFO: Enabling disk erasing on release"
    maas $MAAS_ADMIN_USER maas set-config name=enable_disk_erasing_on_release value=true

    echo "INFO: Disabling secure disk erasing on release"
    maas $MAAS_ADMIN_USER maas set-config name=disk_erase_with_secure_erase value=false

    echo "INFO: Enabling quick disk erasing on release"
    maas $MAAS_ADMIN_USER maas set-config name=disk_erase_with_quick_erase value=true

    echo "INFO: Setting NTP server to $MAAS_NTP"
    maas $MAAS_ADMIN_USER maas set-config name=ntp_servers value=$MAAS_NTP

    echo "INFO: Setting NTP to use external servers only"
    maas $MAAS_ADMIN_USER maas set-config name=ntp_external_only value=true

    #======= MAAS SUBNET CONFIG
    echo "INFO: Setting subnet $subnet as managed"
    maas $MAAS_ADMIN_USER subnet update "$subnet" managed=true

    echo "INFO: Setting DNS $MAAS_DNS for subnet $subnet"
    maas $MAAS_ADMIN_USER subnet update "$subnet" dns_servers=$MAAS_DNS

    echo "INFO: Setting gateway $MAAS_GATEWAY for subnet $subnet"
    maas $MAAS_ADMIN_USER subnet update "$subnet" gateway_ip=$MAAS_GATEWAY

    echo "INFO: Disabling active discovery for subnet $subnet"
    maas $MAAS_ADMIN_USER subnet update "$subnet" active_discovery=false

    echo "INFO: Allowing proxy for $subnet"
    maas $MAAS_ADMIN_USER subnet update "$subnet" allow_proxy=true

    echo "INFO: Allowing DNS for $subnet"
    maas $MAAS_ADMIN_USER subnet update "$subnet" allow_dns=true

    #======= MAAS DHCP CONFIG 
    echo "INFO: Creating DHCP range from $MAAS_DHCP_START to $MAAS_DHCP_END"
    maas $MAAS_ADMIN_USER ipranges create type=dynamic start_ip="$MAAS_DHCP_START" end_ip="$MAAS_DHCP_END" comment='MaaS Dynamic Range'
 
    for reservedIp in ${MAAS_DHCP_RESERVED[@]}; do

        echo "INFO: Reserving IP $reservedIp in DHCP"
        maas $MAAS_ADMIN_USER ipaddresses reserve ip_address="$reservedIp"

    done

    echo "INFO: Reading fabric id for $subnet"
    local fabricId=$(maas $MAAS_ADMIN_USER subnet read "$subnet" | grep \"fabric\": | cut -d ' ' -f 10 | cut -d '"' -f 2)

    echo "INFO: Getting rack controller hostname"
    local rackController=$(maas $MAAS_ADMIN_USER rack-controllers read | grep hostname | cut -d '"' -f 4)

    echo "INFO: Creating space $MAAS_SPACE"
    maas admin spaces create "name=$MAAS_SPACE"

    echo "INFO: Enabling DHCP on rack controller $rackController for subnet $subnet and fabric $fabricId"
    maas $MAAS_ADMIN_USER vlan update $fabricId untagged dhcp_on=true primary_rack="$rackController" space="$MAAS_SPACE"

    #======= MAAS SSH CONFIG 
    echo "INFO: Adding SSH key $MAAS_SSH_KEY"
    maas $MAAS_ADMIN_USER sshkeys create key="$MAAS_SSH_KEY"

    #======= MAAS Install log verbose
    echo "INFO: Enabling verbose curtin logs"
    maas $MAAS_ADMIN_USER maas set-config name=curtin_verbose value=true
    
    #======= MAAS IMAGE CONFIG
    imageCommand="maas $MAAS_ADMIN_USER boot-source-selections create 1 os='$MAAS_OS' release='$MAAS_OS_RELEASE'"

    echo "INFO: Adding images for os $MAAS_OS in release $MAAS_OS_RELEASE"

    for arch in ${MAAS_OS_ARCHES[@]}; do

        echo "INFO: Adding $MAAS_OS $MAAS_OS_RELEASE $arch"
        imageCommand+=" arches='$arch'"

    done

    imageCommand+=" subarches='*' labels='*'"
    bash -c "$imageCommand"

    #======= MAAS ZONE CONFIG 
    echo "INFO: Adding description for default zone"
    maas $MAAS_ADMIN_USER zone update default description="This zone was configured by a script."

    echo "INFO: Adding local lxd pool $MAAS_LOCAL_LXD_POOL"
    maas $MAAS_ADMIN_USER resource-pools create name=$MAAS_LOCAL_LXD_POOL description="local lxd pool"

    echo "INFO: Adding local lxd zone $MAAS_LOCAL_LXD_ZONE"
    maas $MAAS_ADMIN_USER zones create name=$MAAS_LOCAL_LXD_ZONE description="local lxd zone"

    #======= Add local lxd
    echo "INFO: Adding lxd $IP:$LXD_PORT/$MAAS_LOCAL_LXD_NAME with pool $MAAS_LOCAL_LXD_POOL and zone $MAAS_LOCAL_LXD_ZONE"
    maas $MAAS_ADMIN_USER vm-hosts create \
    type=lxd \
    name=$MAAS_LOCAL_LXD_NAME \
    power_address=$IP:$LXD_PORT \
    password="$LXD_SECRET" \
    project="$MAAS_LOCAL_LXD_NAME" \
    zone="$MAAS_LOCAL_LXD_ZONE" \
    pool="$MAAS_LOCAL_LXD_POOL"

    #======= Image Import
    echo "INFO: Triggering image import"
    maas $MAAS_ADMIN_USER boot-resources import


}

removeMaas(){

    echo "INFO: Removing MaaS"

    snap remove --purge maas
    snap remove --purge maas-test-db
    deleteFolder $MAAS_DIR

}


installJuju(){

    echo "INFO: Installing juju $JUJU_VERSION"

    snap install juju --classic --channel="$JUJU_VERSION"

    createFolder $JUJU_DIR
    createFolder "$JUJU_CRED_FOLDER"

    echo "INFO: Creating juju cloud config file $JUJU_CLOUD_YML"

    cat <<EOF >>$JUJU_CLOUD_YML
clouds:
  $JUJU_CLOUD_NAME:
    type: maas
    auth-types: [oauth1]
    endpoint: http://$IP:5240/MAAS
EOF

    echo "INFO: Reading apiKey from file $MAAS_APIKEY_FILE"
    local apiKey=$(cat $MAAS_APIKEY_FILE)

    echo "INFO: Creating juju credentials"

    cat <<EOF >>$JUJU_CRED_YML
credentials:
  $JUJU_CLOUD_NAME:
    anyuser:
      auth-type: oauth1
      maas-oauth: $apiKey
EOF

    chown -R $JUJU_USER:$JUJU_USER $JUJU_CRED_FOLDER
    chown -R $JUJU_USER:$JUJU_USER $JUJU_DIR

    echo "INFO: Adding juju cloud $JUJU_CLOUD_YML as user $JUJU_USER"
    sudo -u $JUJU_USER juju add-cloud --client $JUJU_CLOUD_NAME -f $JUJU_CLOUD_YML

    echo "INFO: Adding juju credentials as user $JUJU_USER"
    sudo -u $JUJU_USER juju add-credential --client $JUJU_CLOUD_NAME -f $JUJU_CRED_YML

}

removeJuju(){

    echo "INFO: Removing Juju"

    snap remove --purge juju
    deleteFolder "$JUJU_CRED_FOLDER"
    deleteFolder $JUJU_DIR

}


####=========================================================================

if [ "$1" = "install" ]; then

    createFolder $SEEDDIR
    disableIpv6
    installRsyslog
    installLxd
    installMaaspower
    installMaas
    installJuju

elif [ "$1" = "remove" ]; then

    removeJuju
    removeMaas
    removeMaaspower
    removeLxd
    removeRsyslog
    enableIpv6
    deleteFolder $SEEDDIR
    apt-get -y autoremove

else
   echo "try install or remove"
fi

