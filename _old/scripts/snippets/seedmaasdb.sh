#!/bin/bash
MAAS_DB_URL="$1"
MAAS_NAME="$2"
MAAS_NTP_STRING_RAW="$3"
MAAS_DNS_STRING_RAW="$4"
MAAS_RPC_SECRET="$5"
MAAS_ZONE="$6"
MAAS_REGION="$7"
MAAS_INTRO_COMPLETE="$8"

MAAS_DNS_STRING=${MAAS_DNS_STRING_RAW//,/ }
MAAS_NTP_STRING=${MAAS_NTP_STRING_RAW//,/ }

function setConfig(){
	
	local DB_URL="$1"
	local KEY="$2"
	local VALUE="$3"
	local TABLE_NAME="maasserver_config"

	local SQL="INSERT INTO $TABLE_NAME (name, value) VALUES ('$KEY', '$VALUE')
	ON CONFLICT (name) DO UPDATE
	SET value = EXCLUDED.value"
	
	echo "INFO: Executing SQL"
	echo "$SQL"

	psql $DB_URL -c "$SQL"
}

function createStructure(){
	
	local DB_URL="$1"
	local TABLE_NAME="$2"
	local NAME="$3"

	local SQL="INSERT INTO $TABLE_NAME (name, description, created, updated) VALUES ('$NAME','$NAME', now(), now())"
	
	echo "INFO: Executing SQL"
	echo "$SQL"

	psql $DB_URL -c "$SQL"
}

function createPool(){
	
	local DB_URL="$1"
	local TABLE_NAME="maasserver_resourcepool"
	local NAME="$2"

	createStructure "$DB_URL" "$TABLE_NAME" "$NAME" 
}

function createZone(){
	
	local DB_URL="$1"
	local TABLE_NAME="maasserver_zone"
	local NAME="$2"

	createStructure "$DB_URL" "$TABLE_NAME" "$NAME" 
}

setConfig "$MAAS_DB_URL" "maas_name" "$MAAS_NAME"
setConfig "$MAAS_DB_URL" "upstream_dns" "$MAAS_DNS_STRING"
setConfig "$MAAS_DB_URL" "ntp_servers" "$MAAS_NTP_STRING"
setConfig "$MAAS_DB_URL" "rpc_shared_secret" "$MAAS_RPC_SECRET"
setConfig "$MAAS_DB_URL" "completed_intro" "$MAAS_INTRO_COMPLETE"

setConfig "$MAAS_DB_URL" "ntp_external_only" "false"
setConfig "$MAAS_DB_URL" "network_discovery" "enabled"
setConfig "$MAAS_DB_URL" "active_discovery_interval" "600"

createZone "$MAAS_DB_URL" "$MAAS_ZONE" 
createPool "$MAAS_DB_URL" "$MAAS_REGION"