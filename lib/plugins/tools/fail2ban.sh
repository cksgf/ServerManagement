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
    yum install python iptables rsyslog -y
    service rsyslog restart
    \cp /var/log/secure /var/log/secure.$(date +"%Y%m%d%H%M%S")
    cat /dev/null > /var/log/secure
elif [ "${PM}" = "apt" ]; then
    apt-get update
    apt-get install python iptables rsyslog -y
    /etc/init.d/rsyslog restart
    \cp /var/log/secure /var/log/secure.$(date +"%Y%m%d%H%M%S")
    cat /dev/null > /var/log/auth.log
fi

echo "Downloading..."
cd ../src
Download_Files ${Download_Mirror}/security/fail2ban/fail2ban-0.10.4.tar.gz fail2ban-0.10.4.tar.gz
tar zxf fail2ban-0.10.4.tar.gz && cd fail2ban-0.10.4
echo "Installing..."
python setup.py install

echo "Copy configure file..."
\cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
cat >>/etc/fail2ban/jail.local<<EOF

[sshd]
enabled  = true
port     = ssh
filter   = sshd
action   = iptables[name=SSH, port=ssh, protocol=tcp]
#mail-whois[name=SSH, dest=yourmail@mail.com]
logpath  = /var/log/auth.log
maxretry = 5
bantime  = 604800
EOF

echo "Copy init files..."
if [ ! -d /var/run/fail2ban ];then
    mkdir /var/run/fail2ban
fi
if [ `/sbin/iptables -h|grep -c "\-w"` -eq 0 ]; then
    sed -i 's/lockingopt =.*/lockingopt =/g' /etc/fail2ban/action.d/iptables-common.conf
fi
if [ "${PM}" = "yum" ]; then
    sed -i 's#logpath  = /var/log/auth.log#logpath  = /var/log/secure#g' /etc/fail2ban/jail.local
    \cp files/redhat-initd /etc/init.d/fail2ban
elif [ "${PM}" = "apt" ]; then
    ln -sf /usr/local/bin/fail2ban-client /usr/bin/fail2ban-client
    \cp files/debian-initd /etc/init.d/fail2ban
fi
chmod +x /etc/init.d/fail2ban
cd ..
rm -rf fail2ban-0.10.4

StartUp fail2ban

echo "Start fail2ban..."
/etc/init.d/fail2ban start