#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use root to install lnmp"
    exit 1
fi

. ../lnmp.conf
. ../include/main.sh
Get_Dist_Name

Press_Start

if [ "${PM}" = "yum" ]; then
    yum install python rsyslog python-ipaddr -y
    service rsyslog restart
    cat /dev/null > /var/log/secure
elif [ "${PM}" = "apt" ]; then
    apt-get update
    apt-get install python rsyslog python-ipaddr -y
    /etc/init.d/rsyslog restart
    cat /dev/null > /var/log/auth.log
fi

echo "Downloading..."
cd ../src
Download_Files ${Download_Mirror}/security/denyhosts/denyhosts-3.1.tar.gz denyhosts-3.1.tar.gz
Tar_Cd denyhosts-3.1.tar.gz denyhosts-3.1
echo "Installing..."
python setup.py install

echo "Copy files..."
\cp denyhosts.conf /etc

if [ "${PM}" = "yum" ]; then
    sed -i 's@^SECURE_LOG = /var/log/auth.log@#SECURE_LOG = /var/log/auth.log@g' /etc/denyhosts.conf
    sed -i 's@^#SECURE_LOG = /var/log/secure@SECURE_LOG = /var/log/secure@g' /etc/denyhosts.conf
    \cp /usr/bin/daemon-control-dist /usr/bin/daemon-control
    chown root /usr/bin/daemon-control
    chmod 700 /usr/bin/daemon-control
    \cp /usr/bin/daemon-control /etc/init.d/denyhosts

    ln -sf /usr/bin/denyhosts.py /usr/sbin/denyhosts
elif [ "${PM}" = "apt" ]; then
    \cp /usr/local/bin/daemon-control-dist /usr/local/bin/daemon-control
    chown root /usr/local/bin/daemon-control
    chmod 700 /usr/local/bin/daemon-control
    \cp /usr/local/bin/daemon-control /etc/init.d/denyhosts

    ln -sf /usr/local/bin/denyhosts.py /usr/sbin/denyhosts

    cat >lsb.ini<<EOF
### BEGIN INIT INFO
# Provides:          denyhosts
# Required-Start:    \$syslog \$local_fs \$time
# Required-Stop:     \$syslog \$local_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start denyhosts and watch .
### END INIT INFO
EOF
    sed -i '9 r lsb.ini' /etc/init.d/denyhosts
    rm -f lsb.ini
fi

sed -i 's#/run/denyhosts.pid#/var/run/denyhosts.pid#g' /etc/init.d/denyhosts
sed -i 's#^PURGE_DENY =.*#PURGE_DENY =1d#g' /etc/denyhosts.conf
sed -i 's@^#PURGE_THRESHOLD = 0@PURGE_THRESHOLD = 3@g' /etc/denyhosts.conf
sed -i '/^IPTABLES/s/^/#/' /etc/denyhosts.conf
sed -i '/^ADMIN_EMAIL/s/^/#/' /etc/denyhosts.conf
sed -i 's#^DENY_THRESHOLD_ROOT =.*#DENY_THRESHOLD_ROOT = 3#g' /etc/denyhosts.conf

sed -i '/STATE_LOCK_EXISTS\ \=\ \-2/aif not os.path.exists("/var/lock/subsys"): os.makedirs("/var/lock/subsys")' /etc/init.d/denyhosts
cd ..
rm -rf denyhosts-3.1

StartUp denyhosts
echo "Start DenyHosts..."
/etc/init.d/denyhosts start