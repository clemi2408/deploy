#!/bin/bash

echo ===== START: VM - INITMAASREGION =====
REGION_USER="$1"
REGION_USER_PASSWORD="$2"
REGION_USER_EMAIL="$3"
REGION_DB_URL="$4"
REGION_CREATE_DB="$5"
REGION_RACK_SECRET="$6"

RACK_SECRET_FILE="/var/snap/maas/common/maas/secret"
REGION_PORT=5240

REGION_IP=$(hostname -I | head -n 1 | xargs)
REGION_URL="http://$REGION_IP:$REGION_PORT/MAAS"      

until pg_isready -d $REGION_DB_URL ; do
  echo >&2 "WARN: Region database not available $REGION_DB_URL - sleeping"
  sleep 5
done

echo "INFO: Configuring MaaS region $REGION_URL"
/snap/bin/maas init region --enable-debug --maas-url "$REGION_URL" --database-uri "$REGION_DB_URL"

if [ "$REGION_CREATE_DB" = "true" ]; then

    echo "INFO: Configuring MaaS region user $REGION_USER $REGION_USER_EMAIL"
    /snap/bin/maas createadmin --username $REGION_USER --password $REGION_USER_PASSWORD --email $REGION_USER_EMAIL --ssh-import ''      

else
    echo "INFO: Using existing region DB $REGION_DB_URL"
fi  


echo "INFO: MaaS region status $REGION_URL"
/snap/bin/maas status

echo "INFO: Writing MaaS rack secret to Database $REGION_DB_URL"
psql $REGION_DB_URL -c "update maasserver_config set value = '$REGION_RACK_SECRET' where id = 1"

echo "INFO: Writing MaaS rack secret to File $RACK_SECRET_FILE"
echo "$RACK_SECRET" > "$RACK_SECRET_FILE"

echo ===== END: VM - INITMAASREGION =====