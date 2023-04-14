#!/bin/bash

JUJU_VERSION="2.9"
JUJU_CLOUD_NAME="maas-cloud"
JUJU_SEED_FOLDER_NAME="juju"
JUJU_CLOUD_FILE_NAME="jujuCloud.yml"
JUJU_CRED_FILE_NAME="jujuCreds.yml"
HOME_PREFIX="/home"
LOCAL_SHARE_FOLDER=".local/share"
#==============================
JUJU_CONTROLLER_NAME="juju01"
JUJU_CONTROLLER_REGION="default"
JUJU_CONTROLLER_SERIES="jammy"
JUJU_CONTROLLER_TIMEOUT=10000
JUJU_CONTROLLER_USER="admin"
JUJU_CONTROLLER_CONSTRAINTS="mem=1.5G cores=1 arch=arm64"

juju_bootstrap(){

    local username="$1"
    local lxdProject="$2"
    local maasZone="$lxdProject-zone"

    sudo -u $username juju bootstrap $JUJU_CLOUD_NAME/$JUJU_CONTROLLER_REGION $JUJU_CONTROLLER_NAME \
    --constraints "$JUJU_CONTROLLER_CONSTRAINTS" \
    --bootstrap-series="$JUJU_CONTROLLER_SERIES" \
    --config bootstrap-timeout=$JUJU_CONTROLLER_TIMEOUT \
    --to zone="$maasZone" \
    --verbose --debug --keep-broken    

    ### Setup Controller
    sudo -u $username juju change-user-password "$JUJU_CONTROLLER_USER"
    sudo -u $username juju dashboard


}



juju_install(){

    local username="$1"
    local maasUser="$2"    

    local userDir="$HOME_PREFIX/$username"
    local jujuDir="$userDir/$JUJU_SEED_FOLDER_NAME"
    local jujuCredentialDir="$userDir/$LOCAL_SHARE_FOLDER"    

    local jujuCloudConfigFile=$jujuDir/$JUJU_CLOUD_FILE_NAME
    local jujuCloudCredentialFile=$jujuDir/$JUJU_CRED_FILE_NAME

    echo "INFO: Installing juju $JUJU_VERSION"
    snap install juju --classic --channel="$JUJU_VERSION"

    commons_createFolder $jujuDir
    commons_createFolder "$jujuCredentialDir"

    echo "INFO: Creating juju cloud config file $jujuCloudConfigFile"

    cat <<EOF >>$jujuCloudConfigFile
clouds:
  $JUJU_CLOUD_NAME:
    type: maas
    auth-types: [oauth1]
    endpoint: http://$IP:5240/MAAS
EOF

    echo "INFO: Getting api key for user $maasUser"
    local apiKey=$(maas apikey --username $maasUser)

    echo "INFO: Creating juju credentials"

    cat <<EOF >>$jujuCloudCredentialFile
credentials:
  $JUJU_CLOUD_NAME:
    anyuser:
      auth-type: oauth1
      maas-oauth: $apiKey
EOF

    commons_setOwnerRecursive "$username" "$jujuCredentialDir"
    commons_setOwnerRecursive "$username" "$jujuDir"

    echo "INFO: Adding juju cloud $jujuCloudConfigFile as user $username"
    sudo -u $username juju add-cloud --client $JUJU_CLOUD_NAME -f $jujuCloudConfigFile

    echo "INFO: Adding juju credentials as user $username"
    sudo -u $username juju add-credential --client $JUJU_CLOUD_NAME -f $jujuCloudCredentialFile

}

juju_remove(){

    local username="$1"    

    local userDir="$HOME_PREFIX/$username"
    local jujuDir="$userDir/$JUJU_SEED_FOLDER_NAME"
    local jujuCredentialDir="$userDir/$LOCAL_SHARE_FOLDER"    

    local jujuCloudConfigFile=$jujuDir/$JUJU_CLOUD_FILE_NAME
    local jujuCloudCredentialFile=$jujuDir/$JUJU_CRED_FILE_NAME

    echo "INFO: Removing Juju"
    snap remove --purge juju

    commons_deleteFolder "$jujuCredentialDir"
    commons_deleteFile "$jujuCloudConfigFile"
    commons_deleteFile "$jujuCloudCredentialFile"
    commons_deleteFolder $jujuDir

}
