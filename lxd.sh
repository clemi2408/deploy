#!/bin/bash

LXD_SEED_FILE=/tmp/lxd-seed.yml

lxd_install(){

	local listenIp="$1"
	local listenPort="$2"
	local bridgeInterface="$3"
	local lxdProject="$4"
	local secret="$5"

    echo "INFO: Installing lxd $listenIp:$listenPort/$lxdProject on bridge $bridgeInterface"

    snap install lxd

    echo "INFO: Creating lxd seed file $LXD_SEED_FILE"

    cat <<EOF >>$LXD_SEED_FILE
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

    echo "INFO: Seeding lxd $LXD_SEED_FILE"
    lxd init --preseed < "$LXD_SEED_FILE"

    echo "INFO: Creating lxd project $lxdProject"
    lxc project create "$lxdProject"

    echo "INFO: Switching to lxd project $lxdProject"
    lxc project switch "$lxdProject"

}

lxd_remove(){
    
    echo "INFO: Removing lxd"

    snap remove --purge lxd

    commons_deleteFile $LXD_SEED_FILE

}
