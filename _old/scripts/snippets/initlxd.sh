#!/bin/bash
echo ===== START: INITLXD =====
LXD_SEED_FILE="$1"
echo "INFO: Seeding LXD from $LXD_SEED_FILE"
/snap/bin/lxd init --preseed < "$LXD_SEED_FILE"
echo "INFO: Disabling LXD secureboot"
/snap/bin/lxc profile set default security.secureboot false
echo ===== END: INITLXD =====