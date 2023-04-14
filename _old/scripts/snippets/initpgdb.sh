#!/bin/bash
echo ===== START: VM - INITPGDB =====
DB_NAME="$1"
DB_OWNER="$2"
PASSWD="$3"
HBA_FILE="/etc/postgresql/12/main/pg_hba.conf"
PG_CONF_FILE="/etc/postgresql/12/main/postgresql.conf"
LISTEN_STRING="listen_addresses = '*'"

function waitForPostgres(){
	until sudo -u postgres psql -c '\l'; do
	    echo >&2 "WARN: Postgres is unavailable - sleeping"
	    sleep 1
	done
}

function showStatus(){
	
	echo "INFO: Listing databases"
	sudo -u postgres psql -c "\l"

}

waitForPostgres

echo "INFO: Writing database config file $PG_CONF_FILE"

echo "$LISTEN_STRING" >> $PG_CONF_FILE

echo "INFO: Creating user $DB_OWNER"
sudo -u postgres psql -c "CREATE USER $DB_OWNER WITH ENCRYPTED PASSWORD '$PASSWD'"
echo "INFO: Creating database $DB_NAME"
sudo -u postgres createdb -O "$DB_OWNER" "$DB_NAME"


echo "INFO: Writing database HBA file $HBA_FILE"

cat > "$HBA_FILE" <<EOL
local   all             postgres                                peer
local   all             all                                     peer
host    all             all             ::1/128                 md5
local   replication     all                                     peer
host    replication     all             127.0.0.1/32            md5
host    replication     all             ::1/128                 md5

host    all             all             0.0.0.0/0            	md5
host    $DB_NAME      $DB_OWNER    0/0       md5
EOL

tail -2 $HBA_FILE



echo "INFO: Restarting database"
service postgresql restart

waitForPostgres
echo ===== END: VM - INITPGDB =====