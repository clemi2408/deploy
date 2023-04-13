#!/bin/bash

JUJU_VERSION="2.9"
JUJU_CLOUD_NAME="maas-cloud"
JUJU_SEED_FOLDER_NAME="juju"
JUJU_CLOUD_FILE_NAME="jujuCloud.yml"
JUJU_CRED_FILE_NAME="jujuCreds.yml"
HOME_PREFIX="/home"
LOCAL_SHARE_FOLDER=".local/share"

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