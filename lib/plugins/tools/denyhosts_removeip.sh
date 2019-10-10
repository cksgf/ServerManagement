#!/bin/bash
# Author:licess
# Website:https://www.vpser.net & https://lnmp.org

HOST=$1
if [ -z "${HOST}" ]; then
    echo "Usage:$0 IP"
    exit 1
fi

echo "Remove IP:${HOST} from denyhosts..."
/etc/init.d/denyhosts stop
echo '
/etc/hosts.deny
/var/lib/denyhosts/hosts
/var/lib/denyhosts/hosts-restricted
/var/lib/denyhosts/hosts-root
/var/lib/denyhosts/hosts-valid
/var/lib/denyhosts/users-hosts
' | grep -v "^$" | xargs sed -i "/${HOST}/d"

#iptables -D INPUT -s ${HOST} -p tcp -m tcp --dport 22 -j DROP
echo " done"
/etc/init.d/denyhosts start