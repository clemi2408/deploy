#!/bin/bash
echo ===== START: INITMAAS =====
#./initmaas.sh admin admin admin@maas.bru.int.cleem.de 
CLOUD_USER="$1"
CLOUD_PASSWORD="$2"
EMAIL="$3"
PORT=5240
IP=$(hostname -I | head -n 1 | xargs)
URL="http://$IP:$PORT/MAAS"      

echo "INFO: Configuring MaaS $URL"
/snap/bin/maas init region+rack --enable-debug --maas-url $URL --database-uri maas-test-db:///      

echo "INFO: Configuring User $CLOUD_USER $EMAIL"
/snap/bin/maas createadmin --username $CLOUD_USER --password $CLOUD_PASSWORD --email $EMAIL --ssh-import ''      

echo "INFO: MaaS status $URL"
/snap/bin/maas status
echo ===== END: INITMAAS =====