#!/bin/bash
echo ===== START: INITLXDWITHMAASVM =====

LXD_SEED_FILE="/opt/cleem/seed/lxdseed.yml"
VM_PROFILE_NAME="maas01-bru-lxc-profile"
VM_TEMPLATE_FILE="/opt/cleem/seed/maas01-bru-lxc-profile.yml"
VM_NAME="maas01"
VM_IMAGE="images:ubuntu/20.04/cloud"

FIRSTBOOT_SERVICE="/etc/systemd/system/firstboot.service"
SEED_FOLDER="/opt/cleem/seed"


bash -c "initlxd.sh $LXD_SEED_FILE"
bash -c "initvm.sh $VM_NAME $VM_PROFILE_FILE $VM_IMAGE"

echo ===== END: INITLXDWITHMAASVM =====
