#!/bin/bash
# ./clientsetup.sh "maas-bru-int-cleem-de" "http://192.168.2.100:5240/MAAS" "Qv6FX6jUc8SHyaUn2s:LNeU9ZpEqXwchFzHht:6JhZAkxUY9AtZkDREeprxNQAdTAQLuRq"
echo ===== START: CLIENT =====

CLOUD_NAME="$1"
URL="$2"
API_KEY="$3"
CONFIG_FILE="$CLOUD_NAME-cloud.yaml"
CREDENTIAL_FILE="$CLOUD_NAME-creds.yaml" 

echo "INFO: $CLOUD_NAME - Install snapd" 
apt install snapd

echo "INFO: $CLOUD_NAME - Install MaaS snap" 
snap install maas

echo "INFO: $CLOUD_NAME - Install juju snap" 
snap install juju --classic

echo "INFO: $CLOUD_NAME - MaaS CLI log in $URL" 
maas login $CLOUD_NAME $URL $API_KEY

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
juju add-cloud --client -f $CONFIG_FILE $CLOUD_NAME        

echo "INFO: $CLOUD_NAME - Adding juju cloud credentials"
juju add-credential --client -f $CREDENTIAL_FILE $CLOUD_NAME   

echo "DONE"
echo "to deploy a juju controller call:"
echo -e "\t\tjuju bootstrap $CLOUD_NAME"


echo ===== END: CLIENT =====   