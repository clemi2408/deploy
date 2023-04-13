#!/bin/bash

RSYSLOG_CONFIG=/etc/rsyslog.conf
RSYSLOG_CONFIG_BACKUP=/etc/rsyslog.bak

rsyslog_enableRemote(){

    echo "INFO: Installing rsyslog"
    apt-get -y install rsyslog

    echo "INFO: Backup rsyslog config $RSYSLOG_CONFIG to $RSYSLOG_CONFIG_BACKUP"
    cp $RSYSLOG_CONFIG $RSYSLOG_CONFIG_BACKUP

    echo "INFO: Enabling rsyslog tcp and udp"
    sed -i '/module(load="imudp")/s/^#//g' $RSYSLOG_CONFIG
    sed -i '/input(type="imudp" port="514")/s/^#//g' $RSYSLOG_CONFIG
    sed -i '/module(load="imtcp")/s/^#//g' $RSYSLOG_CONFIG
    sed -i '/input(type="imtcp" port="514")/s/^#//g' $RSYSLOG_CONFIG

    echo "INFO: Setting custom log template"
    cat >> $RSYSLOG_CONFIG << EOF

#Custom template to generate the log filename dynamically based on the client's IP address.
\$template RemInputLogs, "/var/log/remotelogs/%FROMHOST-IP%/%PROGRAMNAME%.log"
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

    echo "INFO: Restoring rsyslog config backup $RSYSLOG_CONFIG_BACKUP"
    mv $RSYSLOG_CONFIG_BACKUP $RSYSLOG_CONFIG

    echo "INFO: Testing rsyslog config $RSYSLOG_CONFIG"
    rsyslogd -f $RSYSLOG_CONFIG -N1

    echo "INFO: Restarting rsyslog"
    systemctl restart rsyslog
    
}
