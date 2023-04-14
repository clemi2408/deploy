#!/bin/bash

vmname="$1"
templateFile="$2"


profileName="$vmname-profile"
imageName="images:ubuntu/20.04/cloud"


lxc profile create $profileName

cat <<EOF | lxc profile edit $profileName

$(cat $templateFile)

EOF

lxc init $imageName $vmname -p $profileName