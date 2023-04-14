#!/bin/bash
echo ===== START: INITVM =====
VM_NAME="$1"
VM_TEMPLATE_FILE="$2"
VM_IMAGE="$3"
VM_PROFILE_NAME="$VM_NAME-lxc-profile"

echo "INFO: Creating LXD profile $VM_PROFILE_NAME"
/snap/bin/lxc profile create "$VM_PROFILE_NAME"
echo "INFO: Setting LXD profile $VM_PROFILE_NAME with content $2"
/snap/bin/lxc profile edit "$VM_PROFILE_NAME" < "$VM_TEMPLATE_FILE"

echo "INFO: Creating VM $VM_NAME with profile $VM_PROFILE_NAME"
/snap/bin/lxc init "$VM_IMAGE" $VM_NAME -p $VM_PROFILE_NAME
echo "INFO: Setting autostart for VM $VM_NAME with profile $VM_PROFILE_NAME"
/snap/bin/lxc config set "$VM_NAME" boot.autostart true
/snap/bin/lxc "$VM_NAME" start
echo ===== END: INITVM =====