#!/bin/bash
# ./initjuju.sh "maas01" "admin"
echo ===== START: VM - INITJUJU =====

CLOUD_NAME="$1"
CLOUD_USER="$2"

PORT=5240
IP=$(hostname -I | head -n 1 | xargs)
URL="http://$IP:$PORT/MAAS"      

echo "INFO: $CLOUD_NAME - Getting API Key for $CLOUD_USER"      

API_KEY=$(/snap/bin/maas apikey --username $CLOUD_USER)
CONFIG_FILE="/opt/cleem/seed/juju-$CLOUD_NAME-cloud.yaml"
CREDENTIAL_FILE="/opt/cleem/seed/juju-$CLOUD_NAME-creds.yaml"        

echo "INFO: $CLOUD_NAME - Creating juju cloud config $CONFIG_FILE"        

tee "$CONFIG_FILE" > /dev/null << EOF
clouds:
  $CLOUD_NAME:
    type: maas
    auth-types: [oauth1]
    endpoint: $URL
EOF

echo "INFO: $CLOUD_NAME - Creating juju cloud credentials $CREDENTIAL_FILE"        

tee "$CREDENTIAL_FILE" > /dev/null << EOF
credentials:
  $CLOUD_NAME:
    anyuser:
      auth-type: oauth1
      maas-oauth: $API_KEY
EOF

echo "INFO: $CLOUD_NAME - Adding juju cloud config"
/snap/bin/juju add-cloud --client -f $CONFIG_FILE $CLOUD_NAME        

echo "INFO: $CLOUD_NAME - Adding juju cloud credentials"
/snap/bin/juju add-credential --client -f $CREDENTIAL_FILE $CLOUD_NAME      

echo ===== END: VM - INITJUJU =====   