#!/bin/bash

RSYSLOG_CONFIG=/etc/rsyslog.conf

RSYSLOG_SEED_FOLDER_NAME="rsyslog"
RSYSLOG_BACKUP_FILE_NAME="rsyslog-conf.backup"
LOG_FOLDER_NAME="logs"

rsyslog_enableRemote(){

    local seedDir="$1"
    local rsyslogDir="$seedDir/$RSYSLOG_SEED_FOLDER_NAME"
    local rsyslogBackupFile="$rsyslogDir/$RSYSLOG_BACKUP_FILE_NAME"
    local logFolder="$seedDir/$LOG_FOLDER_NAME"

    echo "INFO: Installing rsyslog"

    commons_createFolder $rsyslogDir
    commons_createFolder $logFolder

    apt-get -y install rsyslog

    echo "INFO: Backup rsyslog config $RSYSLOG_CONFIG to $rsyslogBackupFile"
    commons_copyFile "$RSYSLOG_CONFIG" "$rsyslogBackupFile"

    echo "INFO: Enabling rsyslog tcp and udp"
    sed -i '/module(load="imudp")/s/^#//g' $RSYSLOG_CONFIG
    sed -i '/input(type="imudp" port="514")/s/^#//g' $RSYSLOG_CONFIG
    sed -i '/module(load="imtcp")/s/^#//g' $RSYSLOG_CONFIG
    sed -i '/input(type="imtcp" port="514")/s/^#//g' $RSYSLOG_CONFIG

    echo "INFO: Setting custom log template"
    cat >> $RSYSLOG_CONFIG << EOF

#Custom template to generate the log filename dynamically based on the client's IP address.
\$template RemInputLogs, "$logFolder/%FROMHOST-IP%/%PROGRAMNAME%.log"
*.* ?RemInputLogs
EOF

    echo "INFO: Testing rsyslog config $RSYSLOG_CONFIG"
    rsyslogd -f $RSYSLOG_CONFIG -N1

    echo "INFO: Enabling rsyslog"
    systemctl enable rsyslog

    echo "INFO: Starting rsyslog"
    systemctl start rsyslog


}

rsyslog_disableRemote(){

    local seedDir="$1"
    local rsyslogDir="$seedDir/$RSYSLOG_SEED_FOLDER_NAME"
    local rsyslogBackupFile="$rsyslogDir/$RSYSLOG_BACKUP_FILE_NAME"
    local logFolder="$seedDir/$LOG_FOLDER_NAME"

    echo "INFO: Restoring rsyslog config backup $rsyslogBackupFile"
    commons_moveFile "$rsyslogBackupFile" "$RSYSLOG_CONFIG"

    commons_deleteFolder "$rsyslogDir"

    echo "INFO: Testing rsyslog config $RSYSLOG_CONFIG"
    rsyslogd -f $RSYSLOG_CONFIG -N1

    echo "INFO: Restarting rsyslog"
    systemctl restart rsyslog

    commons_deleteFolder "$logFolder"
    
}
