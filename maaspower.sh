#!/bin/bash

MASSPOWER_SEED_FOLDER_NAME="maaspower"
MASSPOWER_CONFIG_FILE_NAME="maaspower.cfg"

MAASPOWER_SERVICE_NAME=maaspower.service
MAASPOWER_SERVICE_FILE=/etc/systemd/system/$MAASPOWER_SERVICE_NAME

maaspower_install(){

    local seedDir="$1"
    local ip="$2"
    local port="$3"
    local user="$4"
    local password="$5"
    local usbId="$6"

    local maasPowerDir="$seedDir/$MASSPOWER_SEED_FOLDER_NAME"
    local maasPowerConfig="$maasPowerDir/$MASSPOWER_CONFIG_FILE_NAME"

    echo "INFO: Installing maaspower"

    commons_createFolder $maasPowerDir

    echo "INFO: Installing uhubctl"
    apt-get -y install uhubctl

    echo "INFO: Installing python"
    apt-get -y install python3.10-venv

    echo "INFO: Creating virtual python environment $maasPowerDir"
    python3 -m venv $maasPowerDir

    echo "INFO: Activating virtual python environment $maasPowerDir"
    source $maasPowerDir/bin/activate

    echo "INFO: Upgrading pip"
    pip install --upgrade pip wheel

    echo "INFO: Installing maaspower"
    python3 -m pip install maaspower

    echo "INFO: Config for maaspower $maasPowerConfig"

    cat <<EOF >>$maasPowerConfig
# yaml-language-server: \$schema=maaspower.schema.json
# NOTE: above relative path to a schema file from 'maaspower schema <filename>'

name: my maaspower control webhooks
ip_address: $ip
port: $port
username: $user
password: $password
devices:
  - type: CommandLine
    name: rpi1
    on: uhubctl -l $usbId -a 1 -p 1
    off: uhubctl -l $usbId -a 0 -p 1
    query: uhubctl -l $usbId -p 1
    query_on_regex: .*power$
    query_off_regex: .*off$
  - type: CommandLine
    name: rpi2
    on: uhubctl -l $usbId -a 1 -p 2
    off: uhubctl -l $usbId -a 0 -p 2
    query: uhubctl -l $usbId -p 2
    query_on_regex: .*power$
    query_off_regex: .*off$
  - type: CommandLine
    name: rpi3
    on: uhubctl -l $usbId -a 1 -p 3
    off: uhubctl -l $usbId -a 0 -p 3
    query: uhubctl -l $usbId -p 3
    query_on_regex: .*power$
    query_off_regex: .*off$
  - type: CommandLine
    name: rpi4
    on: uhubctl -l $usbId -a 1 -p 4
    off: uhubctl -l $usbId -a 0 -p 4
    query: uhubctl -l $usbId -p 4
    query_on_regex: .*power$
    query_off_regex: .*off$
EOF

    echo "INFO: Creating service for maaspower $MAASPOWER_SERVICE_FILE"

    cat <<EOF >>$MAASPOWER_SERVICE_FILE
[Unit]
Description=maaspower daemon
[Service]
ExecStart=$maasPowerDir/bin/maaspower run $maasPowerConfig
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



maaspower_remove(){

    local seedDir="$1"
    local maasPowerDir="$seedDir/$MASSPOWER_SEED_FOLDER_NAME"
    local maasPowerConfig="$maasPowerDir/$MASSPOWER_CONFIG_FILE_NAME"

    echo "INFO: Removing maaspower"
    
    systemctl stop $MAASPOWER_SERVICE_NAME
    systemctl disable $MAASPOWER_SERVICE_NAME
    source $maasPowerDir/bin/activate
    python3 -m pip uninstall -y maaspower
    apt-get -y purge uhubctl
    apt-get -y purge python3.10-venv

    commons_deleteFile $MAASPOWER_SERVICE_FILE
    commons_deleteFile $maasPowerConfig
    commons_deleteFolder $maasPowerDir

}
