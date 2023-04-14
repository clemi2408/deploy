#!/bin/bash

### ======= Runtime parameters
INTERFACE=$(ip route | grep default | cut -d ' ' -f 5)
IP=$(ip -4 addr show dev $INTERFACE | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
TMP_DIR="/tmp"
REPO="https://raw.githubusercontent.com/clemi2408/deploy/main"
LIBS=("commons.sh" "ipv6.sh" "rsyslog.sh" "lxd.sh" "maaspower.sh" "maas.sh" "juju.sh")

### ======= Argument constants
ARG_INSTALL="install"
ARG_REMOVE="remove"
ARG_INSTALL_CONTROLLER="installController"
ARG_REMOVE_CONTROLLER="removeController"

### ======= Functions

downloadLibs(){

   for lib in ${LIBS[@]}; do

        
      local url="$REPO/$lib"
      local target="$TMP_DIR/lib/$lib"

      echo "INFO: Downloading lib $lib via $url to $target"
      curl -s -o $target $url
      source "$target"

    done
}

showHelp(){

   echo "ERROR: Call ./seed.sh {$ARG_INSTALL|$ARG_REMOVE|$ARG_INSTALL_CONTROLLER|$ARG_REMOVE_CONTROLLER} configFile"
   exit 1
}

checkArgs(){

   if [ $# -ne 1 ]; then   

      echo "ERROR: Invalid argument length: $#"
      showHelp   

   fi   

   if [ ! -f "$2" ]; then   

      echo "ERROR: Config File $2 not found"
      showHelp   

   fi
}

loadConfig(){

   local configFile="$1"
   echo "INFO: Using config file $configFile"
   echo "CONFIG: Start"
   cat $configFile
   echo "CONFIG: End"
   echo "INFO: Loading config file $configFile"
   source "$configFile"
}

### ======= Start

checkArgs "$@"
loadConfig "$2"

case "$1" in

  "$ARG_INSTALL")

     downloadLibs
     commons_createFolder "$SEED_DIR"
     ipv6_disable
     rsyslog_enableRemote "$SEED_DIR"
     lxd_install "$SEED_DIR" "$IP" "$LXD_PORT" "$INTERFACE" "$LXD_PROJECT_NAME" "$LXD_SECRET"
     maaspower_install "$SEED_DIR" "$IP" "$MAASPOWER_PORT" "$MAASPOWER_USER" "$MAASPOWER_PASSWORD" "$MAASPOWER_USB_ID"
     maas_install "$SEED_DIR" "$IP" "$MAAS_ADMIN_USER" "$MAAS_ADMIN_PASSWORD" "$IP" "$MAAS_GATEWAY_IP" "$MAAS_DNS_IP" "$MAAS_NTP_IP" "$IP" "$LXD_PORT" "$LXD_PROJECT_NAME" "$LXD_SECRET" "$MAAS_SSH_KEY" "$MAAS_DHCP_START" "$MAAS_DHCP_END"
     juju_installClient "$JUJU_LOCAL_USER" "$MAAS_ADMIN_USER"
     ;;

  "$ARG_REMOVE")

      downloadLibs
      juju_removeClient "$JUJU_LOCAL_USER"
      maas_remove "$SEED_DIR"
      maaspower_remove "$SEED_DIR"
      lxd_remove "$SEED_DIR"
      rsyslog_disableRemote "$SEED_DIR"
      ipv6_enable
      commons_deleteFolder "$SEED_DIR"
      apt-get -y autoremove
      ;;

  "$ARG_INSTALL_CONTROLLER")

      downloadLibs
      juju_installController "$JUJU_LOCAL_USER" "$LXD_PROJECT_NAME" "$JUJU_USER" "$JUJU_PASSWORD"
      ;;

  "$ARG_REMOVE_CONTROLLER")

     downloadLibs
     juju_removeController "$JUJU_LOCAL_USER"
     ;;

  *)

     showHelp
     ;;

esac
