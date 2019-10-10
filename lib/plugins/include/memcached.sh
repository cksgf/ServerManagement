#!/bin/bash

Install_PHPMemcache()
{
    echo "Install memcache php extension..."
    cd ${cur_dir}/src
    if echo "${Cur_PHP_Version}" | grep -Eqi '^7.';then
        rm -rf pecl-memcache
        git clone https://github.com/websupport-sk/pecl-memcache.git
        cd pecl-memcache
    else
        Download_Files ${Download_Mirror}/web/memcache/${PHPMemcache_Ver}.tgz ${PHPMemcache_Ver}.tgz
        Tar_Cd ${PHPMemcache_Ver}.tgz ${PHPMemcache_Ver}
    fi
    ${PHP_Path}/bin/phpize
    ./configure --with-php-config=${PHP_Path}/bin/php-config
    Make_Install
    cd ../
}

Install_PHPMemcached()
{
    echo "Install memcached php extension..."
    cd ${cur_dir}/src
    Get_Dist_Name
    if [ "$PM" = "yum" ]; then
        yum install cyrus-sasl-devel -y
        Get_Dist_Version
        if echo "${CentOS_Version}" | grep -Eqi '^5.'; then
            yum install gcc44 gcc44-c++ libstdc++44-devel -y
            export CC="gcc44"
            export CXX="g++44"
        fi
    elif [ "$PM" = "apt" ]; then
        apt-get install libsasl2-2 sasl2-bin libsasl2-2 libsasl2-dev libsasl2-modules -y
    fi
    Download_Files ${Download_Mirror}/web/libmemcached/${Libmemcached_Ver}.tar.gz
    Tar_Cd ${Libmemcached_Ver}.tar.gz ${Libmemcached_Ver}
    if gcc -dumpversion|grep -q "^[78]"; then
        patch -p1 < ${cur_dir}/src/patch/libmemcached-1.0.18-gcc7.patch
    fi
    ./configure --prefix=/usr/local/libmemcached --with-memcached
    Make_Install
    cd ../

    cd ${cur_dir}/src
    if echo "${Cur_PHP_Version}" | grep -Eqi '^7.';then
        Download_Files ${Download_Mirror}/web/php-memcached/${PHP7Memcached_Ver}.tgz ${PHP7Memcached_Ver}.tgz
        Tar_Cd ${PHP7Memcached_Ver}.tgz ${PHP7Memcached_Ver}
    else
        Download_Files ${Download_Mirror}/web/php-memcached/${PHPMemcached_Ver}.tgz ${PHPMemcached_Ver}.tgz
        Tar_Cd ${PHPMemcached_Ver}.tgz ${PHPMemcached_Ver}
    fi
    ${PHP_Path}/bin/phpize
    ./configure --with-php-config=${PHP_Path}/bin/php-config --enable-memcached --with-libmemcached-dir=/usr/local/libmemcached
    Make_Install
    cd ../
}

Install_Memcached()
{
    ver="1"
    echo "Which memcached php extension do you choose:"
    echo "Install php-memcache,(Discuz x) please enter: 1"
    echo "Install php-memcached, please enter: 2"
    read -p "Enter 1 or 2 (Default 1): " ver

    if [ "${ver}" = "1" ]; then
        echo "You choose php-memcache"
        PHP_ZTS="memcache.so"
    elif [ "${ver}" = "2" ]; then
        echo "You choose php-memcached"
        PHP_ZTS="memcached.so"
    else
        ver="1"
        echo "You choose php-memcache"
        PHP_ZTS="memcache.so"
    fi

    echo "====== Installing memcached ======"
    Press_Start

    rm -f ${PHP_Path}/conf.d/005-memcached.ini
    Addons_Get_PHP_Ext_Dir
    zend_ext=${zend_ext_dir}${PHP_ZTS}
    if [ -s "${zend_ext}" ]; then
        rm -f "${zend_ext}"
    fi

    cat >${PHP_Path}/conf.d/005-memcached.ini<<EOF
extension = ${PHP_ZTS}
EOF

    echo "Install memcached..."
    cd ${cur_dir}/src
    if [ -s /usr/local/memcached/bin/memcached ]; then
        echo "Memcached already exists."
    else
        Download_Files ${Download_Mirror}/web/memcached/${Memcached_Ver}.tar.gz ${Memcached_Ver}.tar.gz
        Tar_Cd ${Memcached_Ver}.tar.gz ${Memcached_Ver}
        ./configure --prefix=/usr/local/memcached
        make &&make install
        cd ../
        rm -rf ${cur_dir}/src/${Memcached_Ver}

        ln -sf /usr/local/memcached/bin/memcached /usr/bin/memcached

        \cp ${cur_dir}/init.d/init.d.memcached /etc/init.d/memcached
        chmod +x /etc/init.d/memcached
        useradd -s /sbin/nologin nobody
    fi

    if [ ! -d /var/lock/subsys ]; then
      mkdir -p /var/lock/subsys
    fi

    StartUp memcached

    if [ "${ver}" = "1" ]; then
        Install_PHPMemcache
    elif [ "${ver}" = "2" ]; then
        Install_PHPMemcached
    fi

    echo "Copy Memcached PHP Test file..."
    \cp ${cur_dir}/conf/memcached${ver}.php ${Default_Website_Dir}/memcached.php

    Restart_PHP

    if [ -s /sbin/iptables ]; then
        if /sbin/iptables -C INPUT -i lo -j ACCEPT; then
            /sbin/iptables -A INPUT -p tcp --dport 11211 -j DROP
            /sbin/iptables -A INPUT -p udp --dport 11211 -j DROP
            if [ "$PM" = "yum" ]; then
                service iptables save
            elif [ "$PM" = "apt" ]; then
                iptables-save > /etc/iptables.rules
            fi
        fi
    fi

    echo "Starting Memcached..."
    /etc/init.d/memcached start

    if [ -s "${zend_ext}" ] && [ -s /usr/local/memcached/bin/memcached ]; then
        Echo_Green "====== Memcached install completed ======"
        Echo_Green "Memcached installed successfully, enjoy it!"
    else
        rm -f ${PHP_Path}/conf.d/005-memcached.ini
        Echo_Red "Memcached install failed!"
    fi
}

Uninstall_Memcached()
{
    echo "You will uninstall Memcached..."
    Press_Start
    rm -f ${PHP_Path}/conf.d/005-memcached.ini
    Restart_PHP
    Remove_StartUp memcached
    echo "Delete Memcached files..."
    rm -rf /usr/local/libmemcached
    rm -rf /usr/local/memcached
    rm -rf /etc/init.d/memcached
    rm -rf /usr/bin/memcached
    if [ -s /sbin/iptables ]; then
        /sbin/iptables -D INPUT -p tcp --dport 11211 -j DROP
        /sbin/iptables -D INPUT -p udp --dport 11211 -j DROP
        if [ "$PM" = "yum" ]; then
            service iptables save
        elif [ "$PM" = "apt" ]; then
            iptables-save > /etc/iptables.rules
        fi
    fi
    Echo_Green "Uninstall Memcached completed."
}
