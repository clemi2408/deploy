#!/bin/bash
IPv6_SYSCTL_FILE=/etc/sysctl.d/10-disable-ipv6.conf

ipv6_disable(){

    if [[ ! -e $IPv6_SYSCTL_FILE ]]; then

        echo "INFO: Disabling IPv6 via File $IPv6_SYSCTL_FILE"

        cat <<EOF >>$IPv6_SYSCTL_FILE
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.lo.disable_ipv6=1
EOF

        sysctl -p

    elif [[ -f $file ]]; then

        echo "WARN: Unable to disable IPv6 file $IPv6_SYSCTL_FILE already exists" 1>&2

    fi

}

ipv6_enable(){

    if [[ ! -e $IPv6_SYSCTL_FILE ]]; then

        echo "WARN: Unable to enable IPv6 by removing file $IPv6_SYSCTL_FILE " 1>&2

    elif [[ -f $file ]]; then

        echo "INFO: Enabling IPv6 by removing file $IPv6_SYSCTL_FILE" 1>&2
        rm $IPv6_SYSCTL_FILE
        sysctl -p
    
    fi

}
