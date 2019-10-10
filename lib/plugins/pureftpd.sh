#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script!"
    exit 1
fi
clear
echo "+----------------------------------------------------------+"
echo "|          Pureftpd for LNMP,  Written by Licess           |"
echo "+----------------------------------------------------------+"
echo "|This script is a tool to install pureftpd for LNMP        |"
echo "+----------------------------------------------------------+"
echo "|For more information please visit https://lnmp.org        |"
echo "+----------------------------------------------------------+"
echo "|Usage: ./pureftpd.sh                                      |"
echo "+----------------------------------------------------------+"
cur_dir=$(pwd)
action=$1

. lnmp.conf
. include/main.sh
. include/init.sh

Get_Dist_Name

Install_Pureftpd()
{
    Press_Install

    Echo_Blue "Installing dependent packages..."
    if [ "$PM" = "yum" ]; then
        for packages in make gcc gcc-c++ gcc-g77 openssl openssl-devel bzip2;
        do yum -y install $packages; done
    elif [ "$PM" = "apt" ]; then
        apt-get update -y
        for packages in build-essential gcc g++ make openssl libssl-dev bzip2;
        do apt-get --no-install-recommends install -y $packages; done
    fi
    Echo_Blue "Download files..."
    cd ${cur_dir}/src
    Download_Files ${Download_Mirror}/ftp/pure-ftpd/${Pureftpd_Ver}.tar.bz2 ${Pureftpd_Ver}.tar.bz2
    if [ $? -eq 0 ]; then
        echo "Download ${Pureftpd_Ver}.tar.bz2 successfully!"
    else
        Download_Files https://download.pureftpd.org/pub/pure-ftpd/releases/${Pureftpd_Ver}.tar.bz2 ${Pureftpd_Ver}.tar.bz2
    fi

    Echo_Blue "Installing pure-ftpd..."
    Tarj_Cd ${Pureftpd_Ver}.tar.bz2 ${Pureftpd_Ver}
    ./configure --prefix=/usr/local/pureftpd CFLAGS=-O2 --with-puredb --with-quotas --with-cookie --with-virtualhosts --with-diraliases --with-sysquotas --with-ratios --with-altlog --with-paranoidmsg --with-shadow --with-welcomemsg --with-throttling --with-uploadscript --with-language=english --with-rfc2640 --with-ftpwho --with-tls

    Make_Install

    Echo_Blue "Copy configure files..."
    mkdir /usr/local/pureftpd/etc
    \cp ${cur_dir}/conf/pure-ftpd.conf /usr/local/pureftpd/etc/pure-ftpd.conf
    if [ -L /etc/init.d/pureftpd ]; then
        rm -f /etc/init.d/pureftpd
    fi
    \cp ${cur_dir}/init.d/init.d.pureftpd /etc/init.d/pureftpd
    chmod +x /etc/init.d/pureftpd
    touch /usr/local/pureftpd/etc/pureftpd.passwd
    touch /usr/local/pureftpd/etc/pureftpd.pdb

    StartUp pureftpd

    cd ..
    rm -rf ${cur_dir}/src/${Pureftpd_Ver}

    if [ -s /sbin/iptables ]; then
        if [ -s /bin/lnmp ]; then
            /sbin/iptables -I INPUT 7 -p tcp --dport 20 -j ACCEPT
            /sbin/iptables -I INPUT 8 -p tcp --dport 21 -j ACCEPT
            /sbin/iptables -I INPUT 9 -p tcp --dport 20000:30000 -j ACCEPT
        else
            /sbin/iptables -I INPUT -p tcp --dport 20 -j ACCEPT
            /sbin/iptables -I INPUT -p tcp --dport 21 -j ACCEPT
            /sbin/iptables -I INPUT -p tcp --dport 20000:30000 -j ACCEPT
        fi
        if [ "${PM}" = "yum" ]; then
            service iptables save
        elif [ "${PM}" = "apt" ]; then
            /sbin/iptables-save > /etc/iptables.rules
        fi
    fi

    if [ ! -s /bin/lnmp ]; then
        \cp ${cur_dir}/conf/lnmp /bin/lnmp
        chmod +x /bin/lnmp
    fi
    id -u www
    if [ $? -ne 0 ]; then
        groupadd www
        useradd -s /sbin/nologin -g www www
    fi

    if [[ -s /usr/local/pureftpd/sbin/pure-ftpd && -s /usr/local/pureftpd/etc/pure-ftpd.conf && -s /etc/init.d/pureftpd ]]; then
        Echo_Blue "Starting pureftpd..."
        /etc/init.d/pureftpd start
        Echo_Green "+----------------------------------------------------------------------+"
        Echo_Green "| Install Pure-FTPd completed,enjoy it!"
        Echo_Green "| =>use command: lnmp ftp {add|list|del|show} to manage FTP users."
        Echo_Green "+----------------------------------------------------------------------+"
        Echo_Green "| For more information please visit https://lnmp.org"
        Echo_Green "+----------------------------------------------------------------------+"
    else
        Echo_Red "Pureftpd install failed!"
    fi
}

Uninstall_Pureftpd()
{
    if [ ! -f /usr/local/pureftpd/sbin/pure-ftpd ]; then
        Echo_Red "Pureftpd was not installed!"
        exit 1
    fi
    echo "Stop pureftpd..."
    /etc/init.d/pureftpd stop
    echo "Remove service..."
    Remove_StartUp pureftpd
    echo "Delete files..."
    rm -f /etc/init.d/pureftpd
    rm -rf /usr/local/pureftpd
    echo "Pureftpd uninstall completed."
}

if [ "${action}" = "uninstall" ]; then
    Uninstall_Pureftpd
else
    Install_Pureftpd 2>&1 | tee /root/pureftpd-install.log
fi
