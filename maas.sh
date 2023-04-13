#!/bin/bash

MAAS_NODE_DEPLOYMENT_TIMEOUT_IN_MIN=90
MAAS_POST_INSTALL_SLEEP_IN_SEC=30
MAAS_STORAGE_LAYOUT="lvm"
MAAS_SPACE=maas-space
MAAS_OS="ubuntu"
MAAS_OS_RELEASE="jammy"
MAAS_OS_ARCHES=("arm64" "amd64")

MAAS_SEED_FOLDER_NAME="maas"
APIKEY_FILE_NAME="apiKey"

maas_install(){

    local seedDir="$1"
    local maasIp="$2"
    local maasUser="$3"
    local maasPassword="$4"
    local syslogIp="$5"
    local gatewayIp="$6"
    local dnsIp="$7"
    local ntpIp="$8"
    local lxdIp="$9"
    local lxdPort="${10}"
    local lxdProject="${11}"
    local lxdSecret="${12}"
    local sshKey="${13}"
    local dhcpStart="${14}"
    local dhcpEnd="${15}"    

    local maasSeedDir="$seedDir/$MAAS_SEED_FOLDER_NAME"    

    commons_createFolder "$maasSeedDir"    

    local apiKeyFile="$maasSeedDir/$APIKEY_FILE_NAME"	    

    local maasLocalLxdPool=$lxdProject-pool
    local maasLocalLxdZone=$lxdProject-zone    

    local subnet=$(ip -o -f inet route |grep -e "link" | awk '{print $1}')
    local maasUrl=http://$maasIp:5240/MAAS

    echo "INFO: Installing MaaS $maasUrl for subnet $subnet"

    #======= INSTALLING 

    echo "INFO: Installing MaaS SNAP"
    snap install maas

    echo "INFO: Installing MaaS DB SNAP"
    snap install maas-test-db

    #======= INITIALIZING 
    echo "INFO: Initializing MaaS"
    maas init region+rack --database-uri maas-test-db:/// --maas-url $maasUrl
   
    #======= CREATING USER 
    echo "INFO: Creating user $maasUser"
    maas createadmin --username $maasUser --password $maasPassword --email $maasUser@$maasIp
    
    #======= CREATING APIKEY 
    echo "INFO: Getting api key for user $maasUser"
    local apiKey=$(maas apikey --username $maasUser)

    echo "INFO: Writing api key for user $maasUser"
    echo $apiKey > $apiKeyFile

    echo "INFO: Sleeping $MAAS_POST_INSTALL_SLEEP_IN_SEC sec"
    sleep $MAAS_POST_INSTALL_SLEEP_IN_SEC

    #======= LOGIN 
    echo "INFO: Login $maasUser to $maasUrl"
    maas login $maasUser $maasUrl "$apiKey"

    #======= STOP Image Import
    echo "INFO: Stopping image import"
    maas $maasUser boot-resources stop-import

    #======= MAAS GENERAL CONFIG 
    echo "INFO: Completing intro"
    maas $maasUser maas set-config name=completed_intro value=true

    echo "INFO: Disabling analytics"
    maas $maasUser maas set-config name=enable_analytics value=false

    echo "INFO: Setting remote syslog $syslogIp"
    maas $maasUser maas set-config name=remote_syslog value="$syslogIp"

    echo "INFO: Setting upstream DNS $dnsIp"
    maas $maasUser maas set-config name=upstream_dns value=$dnsIp

    echo "INFO: Setting provisioning timeout to $MAAS_NODE_DEPLOYMENT_TIMEOUT_IN_MIN minutes"
    maas $maasUser maas set-config name=node_timeout value=$MAAS_NODE_DEPLOYMENT_TIMEOUT_IN_MIN

    echo "INFO: Enabling HTTP proxy"
    maas $maasUser maas set-config name=enable_http_proxy value=true

    echo "INFO: Setting default storage layout to $MAAS_STORAGE_LAYOUT"
    maas $maasUser maas set-config name=default_storage_layout value=$MAAS_STORAGE_LAYOUT

    echo "INFO: Enabling disk erasing on release"
    maas $maasUser maas set-config name=enable_disk_erasing_on_release value=true

    echo "INFO: Disabling secure disk erasing on release"
    maas $maasUser maas set-config name=disk_erase_with_secure_erase value=false

    echo "INFO: Enabling quick disk erasing on release"
    maas $maasUser maas set-config name=disk_erase_with_quick_erase value=true

    echo "INFO: Setting NTP server to $ntpIp"
    maas $maasUser maas set-config name=ntp_servers value=$ntpIp

    echo "INFO: Setting NTP to use external servers only"
    maas $maasUser maas set-config name=ntp_external_only value=true

    #======= MAAS SUBNET CONFIG
    echo "INFO: Setting subnet $subnet as managed"
    maas $maasUser subnet update "$subnet" managed=true

    echo "INFO: Setting DNS $dnsIp for subnet $subnet"
    maas $maasUser subnet update "$subnet" dns_servers=$dnsIp

    echo "INFO: Setting gateway $gatewayIp for subnet $subnet"
    maas $maasUser subnet update "$subnet" gateway_ip=$gatewayIp

    echo "INFO: Disabling active discovery for subnet $subnet"
    maas $maasUser subnet update "$subnet" active_discovery=false

    echo "INFO: Allowing proxy for $subnet"
    maas $maasUser subnet update "$subnet" allow_proxy=true

    echo "INFO: Allowing DNS for $subnet"
    maas $maasUser subnet update "$subnet" allow_dns=true

    #======= MAAS DHCP CONFIG 
    echo "INFO: Creating DHCP range from $dhcpStart to $dhcpEnd"
    maas $maasUser ipranges create type=dynamic start_ip="$dhcpStart" end_ip="$dhcpEnd" comment='MaaS Dynamic Range'
 
#    for reservedIp in ${MAAS_DHCP_RESERVED[@]}; do#

#        echo "INFO: Reserving IP $reservedIp in DHCP"
#        maas $maasUser ipaddresses reserve ip_address="$reservedIp"#

#    done

    echo "INFO: Reading fabric id for $subnet"
    local fabricId=$(maas $maasUser subnet read "$subnet" | grep \"fabric\": | cut -d ' ' -f 10 | cut -d '"' -f 2)

    echo "INFO: Getting rack controller hostname"
    local rackController=$(maas $maasUser rack-controllers read | grep hostname | cut -d '"' -f 4)

    echo "INFO: Creating space $MAAS_SPACE"
    maas admin spaces create "name=$MAAS_SPACE"

    echo "INFO: Enabling DHCP on rack controller $rackController for subnet $subnet and fabric $fabricId"
    maas $maasUser vlan update $fabricId untagged dhcp_on=true primary_rack="$rackController" space="$MAAS_SPACE"

    #======= MAAS SSH CONFIG 
    echo "INFO: Adding SSH key $sshKey"
    maas $maasUser sshkeys create key="$sshKey"

    #======= MAAS Install log verbose
    echo "INFO: Enabling verbose curtin logs"
    maas $maasUser maas set-config name=curtin_verbose value=true
    
    #======= MAAS IMAGE CONFIG
    imageCommand="maas $maasUser boot-source-selections create 1 os='$MAAS_OS' release='$MAAS_OS_RELEASE'"

    echo "INFO: Adding images for os $MAAS_OS in release $MAAS_OS_RELEASE"

    for arch in ${MAAS_OS_ARCHES[@]}; do

        echo "INFO: Adding $MAAS_OS $MAAS_OS_RELEASE $arch"
        imageCommand+=" arches='$arch'"

    done

    imageCommand+=" subarches='*' labels='*'"
    bash -c "$imageCommand"

    #======= MAAS ZONE CONFIG 
    echo "INFO: Adding description for default zone"
    maas $maasUser zone update default description="This zone was configured by a script."

    echo "INFO: Adding local lxd pool $maasLocalLxdPool"
    maas $maasUser resource-pools create name=$maasLocalLxdPool description="local lxd pool"

    echo "INFO: Adding local lxd zone $maasLocalLxdZone"
    maas $maasUser zones create name=$maasLocalLxdZone description="local lxd zone"

    #======= Add local lxd
    echo "INFO: Adding lxd $lxdIp:$lxdPort/$lxdProject with pool $maasLocalLxdPool and zone $maasLocalLxdZone"
    maas $maasUser vm-hosts create \
    type=lxd \
    name=$lxdProject \
    power_address=$lxdIp:$lxdPort \
    password="$lxdSecret" \
    project="$lxdProject" \
    zone="$maasLocalLxdZone" \
    pool="$maasLocalLxdPool"

    #======= Image Import
    echo "INFO: Triggering image import"
    maas $maasUser boot-resources import


}

maas_remove(){

    local seedDir="$1"

    echo "INFO: Removing MaaS"

    snap remove --purge maas
    snap remove --purge maas-test-db

    local apiKeyFile="$maasSeedDir/$APIKEY_FILE_NAME"	
    commons_deleteFile "$apiKeyFile"

    local maasSeedDir="$seedDir/$MAAS_SEED_FOLDER_NAME"
    commons_deleteFolder "$maasSeedDir"

}
