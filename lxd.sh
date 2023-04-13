#!/bin/bash

LXD_SEED_FOLDER_NAME="lxd"
LXD_SEED_FILE_NAME="seed.yml"

lxd_install(){

    local seedDir="$1"
    local listenIp="$2"
    local listenPort="$3"
    local bridgeInterface="$4"
    local lxdProject="$5"
    local secret="$6"    

    local lxdSeedDir="$seedDir/$LXD_SEED_FOLDER_NAME"
    local lxdSeedFile="$lxdSeedDir/$LXD_SEED_FILE_NAME"    

    commons_createFolder "$lxcDir"    

    echo "INFO: Installing lxd $listenIp:$listenPort/$lxdProject on bridge $bridgeInterface"    

    snap install lxd    

    echo "INFO: Creating lxd seed file $lxdSeedFile"

    cat <<EOF >>$lxdSeedFile
config:
  core.https_address: '$listenIp:$listenPort'
  core.trust_password: $secret
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
      parent: $bridgeInterface
      type: nic
    root:
      path: /
      pool: default
      type: disk
  name: default
projects: []
cluster: null
EOF

    echo "INFO: Seeding lxd $lxdSeedFile"
    lxd init --preseed < "$lxdSeedFile"

    echo "INFO: Creating lxd project $lxdProject"
    lxc project create "$lxdProject"

    echo "INFO: Switching to lxd project $lxdProject"
    lxc project switch "$lxdProject"

}

lxd_remove(){
    
    local seedDir="$1"
    local lxdSeedDir="$seedDir/$LXD_SEED_FOLDER_NAME"
    local lxdSeedFile="$lxdSeedDir/$LXD_SEED_FILE_NAME"

    echo "INFO: Removing lxd"

    snap remove --purge lxd

    commons_deleteFile $lxdSeedFile
    commons_deleteFolder $lxdSeedDir

}
