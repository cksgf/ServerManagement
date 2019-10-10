#!/bin/bash

Install_Multiplephp()
{
    Get_Dist_Name
    Check_DB
    Check_Stack
    . include/upgrade_php.sh

    if [ "${Get_Stack}" != "lnmp" ]; then
        echo "Multiple PHP Versions ONLY for LNMP Stack!"
        exit 1
    fi

#which PHP Version do you want to install?
    echo "==========================="

    PHPSelect=""
    Echo_Yellow "You have 9 options for your PHP install."
    echo "1: Install ${PHP_Info[0]}"
    echo "2: Install ${PHP_Info[1]}"
    echo "3: Install ${PHP_Info[2]}"
    echo "4: Install ${PHP_Info[3]}"
    echo "5: Install ${PHP_Info[4]}"
    echo "6: Install ${PHP_Info[5]}"
    echo "7: Install ${PHP_Info[6]}"
    echo "8: Install ${PHP_Info[7]}"
    echo "9: Install ${PHP_Info[8]}"
    read -p "Enter your choice (1, 2, 3, 4, 5, 6, 7, 8 or 9): " PHPSelect

    case "${PHPSelect}" in
    1)
        echo "You will install ${PHP_Info[0]}"
        MPHP_Path='/usr/local/php5.2'
        Check_DB
        if [ "${DB_Name}" == "None" ];then
            Echo_Red "MySQL or MariaDB not found,can't install PHP 5.2!"
            exit 1
        fi
        ;;
    2)
        echo "You will install ${PHP_Info[1]}"
        MPHP_Path='/usr/local/php5.3'
        ;;
    3)
        echo "You will Install ${PHP_Info[2]}"
        MPHP_Path='/usr/local/php5.4'
        ;;
    4)
        echo "You will install ${PHP_Info[3]}"
        MPHP_Path='/usr/local/php5.5'
        ;;
    5)
        echo "You will install ${PHP_Info[4]}"
        MPHP_Path='/usr/local/php5.6'
        ;;
    6)
        echo "You will install ${PHP_Info[5]}"
        MPHP_Path='/usr/local/php7.0'
        ;;
    7)
        echo "You will install ${PHP_Info[6]}"
        MPHP_Path='/usr/local/php7.1'
        ;;
    8)
        echo "You will install ${PHP_Info[7]}"
        MPHP_Path='/usr/local/php7.2'
        ;;
    9)
        echo "You will install ${PHP_Info[8]}"
        MPHP_Path='/usr/local/php7.3'
        ;;
    *)
        echo "No enter,You Must enter one option."
        exit 1
        ;;
    esac

    Press_Install
    if [ -d "${MPHP_Path}" ]; then
        echo "${Php_Ver} already exists!"
        exit 1
    fi
    Check_PHP_Option
    cat /etc/issue
    cat /etc/*-release
    Install_PHP_Dependent

    if [ "${PHPSelect}" = "1" ]; then
        Install_MPHP5.2 2>&1 | tee /root/install-mphp5.2.log
    elif [ "${PHPSelect}" = "2" ]; then
        Install_MPHP5.3 2>&1 | tee /root/install-mphp5.3.log
    elif [ "${PHPSelect}" = "3" ]; then
        Install_MPHP5.4 2>&1 | tee /root/install-mphp5.4.log
    elif [ "${PHPSelect}" = "4" ]; then
        Install_MPHP5.5 2>&1 | tee /root/install-mphp5.5.log
    elif [ "${PHPSelect}" = "5" ]; then
        Install_MPHP5.6 2>&1 | tee /root/install-mphp5.6.log
    elif [ "${PHPSelect}" = "6" ]; then
        Install_MPHP7.0 2>&1 | tee /root/install-mphp7.0.log
    elif [ "${PHPSelect}" = "7" ]; then
        Install_MPHP7.1 2>&1 | tee /root/install-mphp7.1.log
    elif [ "${PHPSelect}" = "8" ]; then
        Install_MPHP7.2 2>&1 | tee /root/install-mphp7.2.log
    elif [ "${PHPSelect}" = "9" ]; then
        Install_MPHP7.3 2>&1 | tee /root/install-mphp7.3.log
    fi
}

Install_MPHP5.2()
{
    cd ${cur_dir}/src
    Download_Files ${Download_Mirror}/web/php/${Php_Ver}.tar.bz2 ${Php_Ver}.tar.bz2
    Download_Files ${Download_Mirror}/web/phpfpm/php-5.2.17-fpm-0.5.14.diff.gz php-5.2.17-fpm-0.5.14.diff.gz

    lnmp stop

    if [[ -s /usr/local/autoconf-2.13/bin/autoconf && -s /usr/local/autoconf-2.13/bin/autoheader ]]; then
        Echo_Green "Autconf 2.13...ok"
    else
        Install_Autoconf
    fi

    ln -s /usr/lib/libevent-1.4.so.2 /usr/local/lib/libevent-1.4.so.2
    ln -s /usr/lib/libltdl.so /usr/lib/libltdl.so.3

    cd ${cur_dir}/src
    rm -rf php-5.2.17
    Check_Curl

    echo "Start install ${Php_Ver}....."
    Export_PHP_Autoconf
    tar jxf ${Php_Ver}.tar.bz2
    gzip -cd php-5.2.17-fpm-0.5.14.diff.gz | patch -d ${Php_Ver} -p1
    cd ${Php_Ver}
    patch -p1 < ${cur_dir}/src/patch/php-5.2.17-max-input-vars.patch
    patch -p0 < ${cur_dir}/src/patch/php-5.2.17-xml.patch
    patch -p1 < ${cur_dir}/src/patch/debian_patches_disable_SSLv2_for_openssl_1_0_0.patch
    ./buildconf --force
    ./configure --prefix=${MPHP_Path} --with-config-file-path=${MPHP_Path}/etc --with-config-file-scan-dir=${MPHP_Path}/conf.d --with-mysql=${MySQL_Dir} --with-mysqli=${MySQL_Config} --with-pdo-mysql=${MySQL_Dir} --with-iconv-dir --with-freetype-dir=/usr/local/freetype --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --enable-discard-path --enable-magic-quotes --enable-safe-mode --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --with-curl=/usr/local/curl --enable-mbregex --enable-fastcgi --enable-fpm --enable-force-cgi-redirect --enable-mbstring --with-mcrypt --enable-ftp --with-gd --enable-gd-native-ttf ${with_openssl} --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --with-gettext --with-mime-magic
    PHP_Make_Install

    mkdir -p ${MPHP_Path}/{etc,conf.d}
    \cp php.ini-dist ${MPHP_Path}/etc/php.ini

    # php extensions
    sed -i 's#extension_dir = "./"#extension_dir = "${MPHP_Path}/lib/php/extensions/no-debug-non-zts-20060613/"\n#' ${MPHP_Path}/etc/php.ini
    sed -i 's#output_buffering = Off#output_buffering = On#' ${MPHP_Path}/etc/php.ini
    sed -i 's/post_max_size = 8M/post_max_size = 50M/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 50M/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/;date.timezone =/date.timezone = PRC/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/short_open_tag = Off/short_open_tag = On/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/; cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/; cgi.fix_pathinfo=0/cgi.fix_pathinfo=0/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/max_execution_time = 30/max_execution_time = 300/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/disable_functions =.*/disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,proc_open,proc_get_status,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server,fsocket/g' ${MPHP_Path}/etc/php.ini

    cd ${cur_dir}/src
    if [ "${Is_64bit}" = "y" ] ; then
        Download_Files ${Download_Mirror}/web/zend/ZendOptimizer-3.3.9-linux-glibc23-x86_64.tar.gz
        tar zxf ZendOptimizer-3.3.9-linux-glibc23-x86_64.tar.gz
        mkdir -p /usr/local/zend52/
        \cp ZendOptimizer-3.3.9-linux-glibc23-x86_64/data/5_2_x_comp/ZendOptimizer.so /usr/local/zend52/ZendOptimizer5.2.so
    else
        Download_Files ${Download_Mirror}/web/zend/ZendOptimizer-3.3.9-linux-glibc23-i386.tar.gz
        tar zxf ZendOptimizer-3.3.9-linux-glibc23-i386.tar.gz
        mkdir -p /usr/local/zend52/
        \cp ZendOptimizer-3.3.9-linux-glibc23-i386/data/5_2_x_comp/ZendOptimizer.so /usr/local/zend52/ZendOptimizer5.2.so
    fi

    cat >${MPHP_Path}/conf.d/002-zendoptimizer.ini<<EOF
[Zend Optimizer]
zend_optimizer.optimization_level=1
zend_extension="/usr/local/zend52/ZendOptimizer5.2.so"
EOF

    rm -f ${MPHP_Path}/etc/php-fpm.conf
    \cp ${cur_dir}/conf/php-fpm5.2.conf ${MPHP_Path}/etc/php-fpm.conf
    \cp ${cur_dir}/conf/enable-php5.2.conf /usr/local/nginx/conf/enable-php5.2.conf
    \cp ${cur_dir}/init.d/init.d.php-fpm5.2 /etc/init.d/php-fpm5.2
    chmod +x /etc/init.d/php-fpm5.2

    sed -i "s#/usr/local/php/#${MPHP_Path}/#g" ${MPHP_Path}/etc/php-fpm.conf
    sed -i 's#php-cgi.sock#php-cgi5.2.sock#g' ${MPHP_Path}/etc/php-fpm.conf
    sed -i "s#/usr/local/php/#${MPHP_Path}/#g" /etc/init.d/php-fpm5.2
    sed -i 's@# Provides:          php-fpm@# Provides:          php-fpm5.2@g' /etc/init.d/php-fpm5.2

    StartUp php-fpm5.2

    sleep 2

    lnmp start

    rm -rf ${cur_dir}/src/${Php_Ver}

    if [ -s ${MPHP_Path}/sbin/php-fpm ] && [ -s ${MPHP_Path}/etc/php.ini ] && [ -s ${MPHP_Path}/bin/php ]; then
        echo "==========================================="
        Echo_Green "You have successfully install ${Php_Ver}"
        echo "==========================================="
    else
        rm -rf ${MPHP_Path}
        Echo_Red "Failed to install ${Php_Ver}, you can download /root/install-mphp5.2.log from your server, and upload install-mphp5.2.log to LNMP Forum."
    fi
}

Install_MPHP5.3()
{
    lnmp stop

    cd ${cur_dir}/src
    Check_Curl
    Download_Files ${Download_Mirror}/web/php/${Php_Ver}.tar.bz2 ${Php_Ver}.tar.bz2
    Echo_Blue "[+] Installing ${Php_Ver}..."
    Tarj_Cd ${Php_Ver}.tar.bz2 ${Php_Ver}
    patch -p1 < ${cur_dir}/src/patch/php-5.3-multipart-form-data.patch
    ./configure --prefix=${MPHP_Path} --with-config-file-path=${MPHP_Path}/etc --with-config-file-scan-dir=${MPHP_Path}/conf.d --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv-dir --with-freetype-dir=/usr/local/freetype --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-magic-quotes --enable-safe-mode --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --with-curl=/usr/local/curl --enable-mbregex --enable-mbstring --with-mcrypt --enable-ftp --with-gd --enable-gd-native-ttf ${with_openssl} --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --with-gettext ${with_fileinfo} ${PHP_Modules_Options}

    PHP_Make_Install

    echo "Copy new php configure file..."
    mkdir -p ${MPHP_Path}/{etc,conf.d}
    \cp php.ini-production ${MPHP_Path}/etc/php.ini

    cd ${cur_dir}
    # php extensions
    echo "Modify php.ini......"
    sed -i 's/post_max_size =.*/post_max_size = 50M/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/upload_max_filesize =.*/upload_max_filesize = 50M/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/;date.timezone =.*/date.timezone = PRC/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/short_open_tag =.*/short_open_tag = On/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/;cgi.fix_pathinfo=.*/cgi.fix_pathinfo=0/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/max_execution_time =.*/max_execution_time = 300/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/register_long_arrays =.*/;register_long_arrays = On/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/magic_quotes_gpc =.*/;magic_quotes_gpc = On/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/disable_functions =.*/disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,proc_open,proc_get_status,popen,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server/g' ${MPHP_Path}/etc/php.ini

    echo "Install ZendGuardLoader for PHP 5.3..."
    cd ${cur_dir}/src
    if [ "${Is_64bit}" = "y" ] ; then
        Download_Files ${Download_Mirror}/web/zend/ZendGuardLoader-php-5.3-linux-glibc23-x86_64.tar.gz
        tar zxf ZendGuardLoader-php-5.3-linux-glibc23-x86_64.tar.gz
        mkdir -p /usr/local/zend/
        \cp ZendGuardLoader-php-5.3-linux-glibc23-x86_64/php-5.3.x/ZendGuardLoader.so /usr/local/zend/ZendGuardLoader5.3.so
    else
        Download_Files ${Download_Mirror}/web/zend/ZendGuardLoader-php-5.3-linux-glibc23-i386.tar.gz
        tar zxf ZendGuardLoader-php-5.3-linux-glibc23-i386.tar.gz
        mkdir -p /usr/local/zend/
        \cp ZendGuardLoader-php-5.3-linux-glibc23-i386/php-5.3.x/ZendGuardLoader.so /usr/local/zend/ZendGuardLoader5.3.so
    fi

    echo "Write ZendGuardLoader to php.ini..."
    cat >${MPHP_Path}/conf.d/002-zendguardloader.ini<<EOF
[Zend ZendGuard Loader]
zend_extension=/usr/local/zend/ZendGuardLoader5.3.so
zend_loader.enable=1
zend_loader.disable_licensing=0
zend_loader.obfuscation_level_support=3
zend_loader.license_path=
EOF

    echo "Creating new php-fpm configure file..."
    cat >${MPHP_Path}/etc/php-fpm.conf<<EOF
[global]
pid = ${MPHP_Path}/var/run/php-fpm.pid
error_log = ${MPHP_Path}/var/log/php-fpm.log
log_level = notice

[www]
listen = /tmp/php-cgi5.3.sock
listen.backlog = -1
listen.allowed_clients = 127.0.0.1
listen.owner = www
listen.group = www
listen.mode = 0666
user = www
group = www
pm = dynamic
pm.max_children = 10
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 6
request_terminate_timeout = 100
request_slowlog_timeout = 0
slowlog = var/log/slow.log
EOF

    echo "Copy php-fpm init.d file..."
    \cp ${cur_dir}/src/${Php_Ver}/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm5.3
    chmod +x /etc/init.d/php-fpm5.3

    StartUp php-fpm5.3

    \cp ${cur_dir}/conf/enable-php5.3.conf /usr/local/nginx/conf/enable-php5.3.conf

    sleep 2

    lnmp start

    rm -rf ${cur_dir}/src/${Php_Ver}

    if [ -s ${MPHP_Path}/sbin/php-fpm ] && [ -s ${MPHP_Path}/etc/php.ini ] && [ -s ${MPHP_Path}/bin/php ]; then
        echo "==========================================="
        Echo_Green "You have successfully install ${Php_Ver} "
        echo "==========================================="
    else
        rm -rf ${MPHP_Path}
        Echo_Red "Failed to install ${Php_Ver}, you can download /root/install-mphp5.3.log from your server, and upload install-mphp5.3.log to LNMP Forum."
    fi
}

Install_MPHP5.4()
{
    lnmp stop

    cd ${cur_dir}/src
    Download_Files ${Download_Mirror}/web/php/${Php_Ver}.tar.bz2 ${Php_Ver}.tar.bz2
    Echo_Blue "[+] Installing ${Php_Ver}..."
    Tarj_Cd ${Php_Ver}.tar.bz2 ${Php_Ver}
    ./configure --prefix=${MPHP_Path} --with-config-file-path=${MPHP_Path}/etc --with-config-file-scan-dir=${MPHP_Path}/conf.d --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv-dir --with-freetype-dir=/usr/local/freetype --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization ${with_curl} --enable-mbregex --enable-mbstring --with-mcrypt --enable-ftp --with-gd --enable-gd-native-ttf ${with_openssl} --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --with-gettext ${with_fileinfo} --enable-intl --with-xsl ${PHP_Modules_Options}

    PHP_Make_Install

    echo "Copy new php configure file..."
    mkdir -p ${MPHP_Path}/{etc,conf.d}
    \cp php.ini-production ${MPHP_Path}/etc/php.ini

    cd ${cur_dir}
    # php extensions
    echo "Modify php.ini......"
    sed -i 's/post_max_size =.*/post_max_size = 50M/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/upload_max_filesize =.*/upload_max_filesize = 50M/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/;date.timezone =.*/date.timezone = PRC/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/short_open_tag =.*/short_open_tag = On/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/;cgi.fix_pathinfo=.*/cgi.fix_pathinfo=0/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/max_execution_time =.*/max_execution_time = 300/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/disable_functions =.*/disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,proc_open,proc_get_status,popen,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server/g' ${MPHP_Path}/etc/php.ini

    echo "Install ZendGuardLoader for PHP 5.4..."
    cd ${cur_dir}/src
    if [ "${Is_64bit}" = "y" ] ; then
        Download_Files ${Download_Mirror}/web/zend/ZendGuardLoader-70429-PHP-5.4-linux-glibc23-x86_64.tar.gz
        tar zxf ZendGuardLoader-70429-PHP-5.4-linux-glibc23-x86_64.tar.gz
        mkdir -p /usr/local/zend/
        \cp ZendGuardLoader-70429-PHP-5.4-linux-glibc23-x86_64/php-5.4.x/ZendGuardLoader.so /usr/local/zend/ZendGuardLoader5.4.so
    else
        Download_Files ${Download_Mirror}/web/zend/ZendGuardLoader-70429-PHP-5.4-linux-glibc23-i386.tar.gz
        tar zxf ZendGuardLoader-70429-PHP-5.4-linux-glibc23-i386.tar.gz
        mkdir -p /usr/local/zend/
        \cp ZendGuardLoader-70429-PHP-5.4-linux-glibc23-i386/php-5.4.x/ZendGuardLoader.so /usr/local/zend/ZendGuardLoader5.4.so
    fi

    echo "Write ZendGuardLoader to php.ini..."
    cat >${MPHP_Path}/conf.d/002-zendguardloader.ini<<EOF
[Zend ZendGuard Loader]
zend_extension=/usr/local/zend/ZendGuardLoader5.4.so
zend_loader.enable=1
zend_loader.disable_licensing=0
zend_loader.obfuscation_level_support=3
zend_loader.license_path=
EOF

    echo "Creating new php-fpm configure file..."
    cat >${MPHP_Path}/etc/php-fpm.conf<<EOF
[global]
pid = ${MPHP_Path}/var/run/php-fpm.pid
error_log = ${MPHP_Path}/var/log/php-fpm.log
log_level = notice

[www]
listen = /tmp/php-cgi5.4.sock
listen.backlog = -1
listen.allowed_clients = 127.0.0.1
listen.owner = www
listen.group = www
listen.mode = 0666
user = www
group = www
pm = dynamic
pm.max_children = 10
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 6
request_terminate_timeout = 100
request_slowlog_timeout = 0
slowlog = var/log/slow.log
EOF

    echo "Copy php-fpm init.d file..."
    \cp ${cur_dir}/src/${Php_Ver}/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm5.4
    chmod +x /etc/init.d/php-fpm5.4

    StartUp php-fpm5.4

    \cp ${cur_dir}/conf/enable-php5.4.conf /usr/local/nginx/conf/enable-php5.4.conf

    sleep 2

    lnmp start

    rm -rf ${cur_dir}/src/${Php_Ver}

    if [ -s ${MPHP_Path}/sbin/php-fpm ] && [ -s ${MPHP_Path}/etc/php.ini ] && [ -s ${MPHP_Path}/bin/php ]; then
        echo "==========================================="
        Echo_Green "You have successfully install ${Php_Ver} "
        echo "==========================================="
    else
        rm -rf ${MPHP_Path}
        Echo_Red "Failed to install ${Php_Ver}, you can download /root/install-mphp5.4.log from your server, and upload install-mphp5.4.log to LNMP Forum."
    fi
}

Install_MPHP5.5()
{
    lnmp stop

    cd ${cur_dir}/src
    Download_Files ${Download_Mirror}/web/php/${Php_Ver}.tar.bz2 ${Php_Ver}.tar.bz2
    Echo_Blue "[+] Installing ${Php_Ver}..."
    Tarj_Cd ${Php_Ver}.tar.bz2 ${Php_Ver}
    ./configure --prefix=${MPHP_Path} --with-config-file-path=${MPHP_Path}/etc --with-config-file-scan-dir=${MPHP_Path}/conf.d --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv-dir --with-freetype-dir=/usr/local/freetype --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization ${with_curl} --enable-mbregex --enable-mbstring --with-mcrypt --enable-ftp --with-gd --enable-gd-native-ttf ${with_openssl} --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --with-gettext ${with_fileinfo} --enable-opcache --enable-intl --with-xsl ${PHP_Modules_Options}

    PHP_Make_Install

    echo "Copy new php configure file..."
    mkdir -p ${MPHP_Path}/{etc,conf.d}
    \cp php.ini-production ${MPHP_Path}/etc/php.ini

    cd ${cur_dir}
    # php extensions
    echo "Modify php.ini..."
    sed -i 's/post_max_size =.*/post_max_size = 50M/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/upload_max_filesize =.*/upload_max_filesize = 50M/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/;date.timezone =.*/date.timezone = PRC/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/short_open_tag =.*/short_open_tag = On/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/;cgi.fix_pathinfo=.*/cgi.fix_pathinfo=0/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/max_execution_time =.*/max_execution_time = 300/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/disable_functions =.*/disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,proc_open,proc_get_status,popen,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server/g' ${MPHP_Path}/etc/php.ini

    echo "Install ZendGuardLoader for PHP 5.5..."
    cd ${cur_dir}/src
    if [ "${Is_64bit}" = "y" ] ; then
        Download_Files ${Download_Mirror}/web/zend/zend-loader-php5.5-linux-x86_64.tar.gz
        tar zxf zend-loader-php5.5-linux-x86_64.tar.gz
        mkdir -p /usr/local/zend/
        \cp zend-loader-php5.5-linux-x86_64/ZendGuardLoader.so /usr/local/zend/ZendGuardLoader5.5.so
    else
        Download_Files ${Download_Mirror}/web/zend/zend-loader-php5.5-linux-i386.tar.gz
        tar zxf zend-loader-php5.5-linux-i386.tar.gz
        mkdir -p /usr/local/zend/
        \cp zend-loader-php5.5-linux-i386/ZendGuardLoader.so /usr/local/zend/ZendGuardLoader5.5.so
    fi

    echo "Write ZendGuardLoader to php.ini..."
    cat >${MPHP_Path}/conf.d/002-zendguardloader.ini<<EOF
[Zend ZendGuard Loader]
zend_extension=/usr/local/zend/ZendGuardLoader5.5.so
zend_loader.enable=1
zend_loader.disable_licensing=0
zend_loader.obfuscation_level_support=3
zend_loader.license_path=
EOF

    echo "Creating new php-fpm configure file..."
    cat >${MPHP_Path}/etc/php-fpm.conf<<EOF
[global]
pid = ${MPHP_Path}/var/run/php-fpm.pid
error_log = ${MPHP_Path}/var/log/php-fpm.log
log_level = notice

[www]
listen = /tmp/php-cgi5.5.sock
listen.backlog = -1
listen.allowed_clients = 127.0.0.1
listen.owner = www
listen.group = www
listen.mode = 0666
user = www
group = www
pm = dynamic
pm.max_children = 10
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 6
request_terminate_timeout = 100
request_slowlog_timeout = 0
slowlog = var/log/slow.log
EOF

    echo "Copy php-fpm init.d file..."
    \cp ${cur_dir}/src/${Php_Ver}/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm5.5
    chmod +x /etc/init.d/php-fpm5.5

    StartUp php-fpm5.5

    \cp ${cur_dir}/conf/enable-php5.5.conf /usr/local/nginx/conf/enable-php5.5.conf

    sleep 2

    lnmp start

    rm -rf ${cur_dir}/src/${Php_Ver}

    if [ -s ${MPHP_Path}/sbin/php-fpm ] && [ -s ${MPHP_Path}/etc/php.ini ] && [ -s ${MPHP_Path}/bin/php ]; then
        echo "==========================================="
        Echo_Green "You have successfully install ${Php_Ver} "
        echo "==========================================="
    else
        rm -rf ${MPHP_Path}
        Echo_Red "Failed to install ${Php_Ver}, you can download /root/install-mphp5.5.log from your server, and upload install-mphp5.5.log to LNMP Forum."
    fi
}

Install_MPHP5.6()
{
    lnmp stop

    cd ${cur_dir}/src
    Download_Files ${Download_Mirror}/web/php/${Php_Ver}.tar.bz2 ${Php_Ver}.tar.bz2
    Echo_Blue "[+] Installing ${Php_Ver}"
    Tarj_Cd ${Php_Ver}.tar.bz2 ${Php_Ver}
    ./configure --prefix=${MPHP_Path} --with-config-file-path=${MPHP_Path}/etc --with-config-file-scan-dir=${MPHP_Path}/conf.d --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv-dir --with-freetype-dir=/usr/local/freetype --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization ${with_curl} --enable-mbregex --enable-mbstring --with-mcrypt --enable-ftp --with-gd --enable-gd-native-ttf ${with_openssl} --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --with-gettext ${with_fileinfo} --enable-opcache --enable-intl --with-xsl ${PHP_Modules_Options}

    PHP_Make_Install

    echo "Copy new php configure file..."
    mkdir -p ${MPHP_Path}/{etc,conf.d}
    \cp php.ini-production ${MPHP_Path}/etc/php.ini

    cd ${cur_dir}
    # php extensions
    echo "Modify php.ini......"
    sed -i 's/post_max_size =.*/post_max_size = 50M/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/upload_max_filesize =.*/upload_max_filesize = 50M/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/;date.timezone =.*/date.timezone = PRC/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/short_open_tag =.*/short_open_tag = On/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/;cgi.fix_pathinfo=.*/cgi.fix_pathinfo=0/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/max_execution_time =.*/max_execution_time = 300/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/disable_functions =.*/disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,proc_open,proc_get_status,popen,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server/g' ${MPHP_Path}/etc/php.ini

    echo "Install ZendGuardLoader for PHP 5.6..."
    cd ${cur_dir}/src
    if [ "${Is_64bit}" = "y" ] ; then
        Download_Files ${Download_Mirror}/web/zend/zend-loader-php5.6-linux-x86_64.tar.gz
        tar zxf zend-loader-php5.6-linux-x86_64.tar.gz
        mkdir -p /usr/local/zend/
        \cp zend-loader-php5.6-linux-x86_64/ZendGuardLoader.so /usr/local/zend/ZendGuardLoader5.6.so
    else
        Download_Files ${Download_Mirror}/web/zend/zend-loader-php5.6-linux-i386.tar.gz
        tar zxf zend-loader-php5.6-linux-i386.tar.gz
        mkdir -p /usr/local/zend/
        \cp zend-loader-php5.6-linux-i386/ZendGuardLoader.so /usr/local/zend/ZendGuardLoader5.6.so
    fi

    echo "Write ZendGuardLoader to php.ini..."
    cat >${MPHP_Path}/conf.d/002-zendguardloader.ini<<EOF
[Zend ZendGuard Loader]
zend_extension=/usr/local/zend/ZendGuardLoader5.6.so
zend_loader.enable=1
zend_loader.disable_licensing=0
zend_loader.obfuscation_level_support=3
zend_loader.license_path=
EOF

    echo "Creating new php-fpm configure file..."
    cat >${MPHP_Path}/etc/php-fpm.conf<<EOF
[global]
pid = ${MPHP_Path}/var/run/php-fpm.pid
error_log = ${MPHP_Path}/var/log/php-fpm.log
log_level = notice

[www]
listen = /tmp/php-cgi5.6.sock
listen.backlog = -1
listen.allowed_clients = 127.0.0.1
listen.owner = www
listen.group = www
listen.mode = 0666
user = www
group = www
pm = dynamic
pm.max_children = 10
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 6
request_terminate_timeout = 100
request_slowlog_timeout = 0
slowlog = var/log/slow.log
EOF

    echo "Copy php-fpm init.d file..."
    \cp ${cur_dir}/src/${Php_Ver}/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm5.6
    chmod +x /etc/init.d/php-fpm5.6

    StartUp php-fpm5.6

    \cp ${cur_dir}/conf/enable-php5.6.conf /usr/local/nginx/conf/enable-php5.6.conf

    sleep 2

    lnmp start

    rm -rf ${cur_dir}/src/${Php_Ver}

    if [ -s ${MPHP_Path}/sbin/php-fpm ] && [ -s ${MPHP_Path}/etc/php.ini ] && [ -s ${MPHP_Path}/bin/php ]; then
        echo "==========================================="
        Echo_Green "You have successfully install ${Php_Ver} "
        echo "==========================================="
    else
        rm -rf ${MPHP_Path}
        Echo_Red "Failed to install ${Php_Ver}, you can download /root/install-mphp5.6.log from your server, and upload install-mphp5.6.log to LNMP Forum."
    fi
}

Install_MPHP7.0()
{
    lnmp stop

    cd ${cur_dir}/src
    Download_Files ${Download_Mirror}/web/php/${Php_Ver}.tar.bz2 ${Php_Ver}.tar.bz2
    Echo_Blue "[+] Installing ${Php_Ver}"
    Tarj_Cd ${Php_Ver}.tar.bz2 ${Php_Ver}
    ./configure --prefix=${MPHP_Path} --with-config-file-path=${MPHP_Path}/etc --with-config-file-scan-dir=${MPHP_Path}/conf.d --enable-fpm --with-fpm-user=www --with-fpm-group=www --enable-mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv-dir --with-freetype-dir=/usr/local/freetype --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization ${with_curl} --enable-mbregex --enable-mbstring --enable-intl --enable-pcntl --with-mcrypt --enable-ftp --with-gd --enable-gd-native-ttf ${with_openssl} --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --with-gettext ${with_fileinfo} --enable-opcache --with-xsl ${PHP_Modules_Options}

    PHP_Make_Install

    echo "Copy new php configure file..."
    mkdir -p ${MPHP_Path}/{etc,conf.d}
    \cp php.ini-production ${MPHP_Path}/etc/php.ini

    cd ${cur_dir}
    # php extensions
    echo "Modify php.ini......"
    sed -i 's/post_max_size =.*/post_max_size = 50M/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/upload_max_filesize =.*/upload_max_filesize = 50M/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/;date.timezone =.*/date.timezone = PRC/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/short_open_tag =.*/short_open_tag = On/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/;cgi.fix_pathinfo=.*/cgi.fix_pathinfo=0/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/max_execution_time =.*/max_execution_time = 300/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/disable_functions =.*/disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,proc_open,proc_get_status,popen,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server/g' ${MPHP_Path}/etc/php.ini

    echo "Install ZendGuardLoader for PHP 7..."
    echo "unavailable now."

    echo "Creating new php-fpm configure file..."
    cat >${MPHP_Path}/etc/php-fpm.conf<<EOF
[global]
pid = ${MPHP_Path}/var/run/php-fpm.pid
error_log = ${MPHP_Path}/var/log/php-fpm.log
log_level = notice

[www]
listen = /tmp/php-cgi7.0.sock
listen.backlog = -1
listen.allowed_clients = 127.0.0.1
listen.owner = www
listen.group = www
listen.mode = 0666
user = www
group = www
pm = dynamic
pm.max_children = 10
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 6
request_terminate_timeout = 100
request_slowlog_timeout = 0
slowlog = var/log/slow.log
EOF

    echo "Copy php-fpm init.d file..."
    \cp ${cur_dir}/src/${Php_Ver}/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm7.0
    chmod +x /etc/init.d/php-fpm7.0

    StartUp php-fpm7.0

    \cp ${cur_dir}/conf/enable-php7.0.conf /usr/local/nginx/conf/enable-php7.0.conf

    sleep 2

    lnmp start

    rm -rf ${cur_dir}/src/${Php_Ver}

    if [ -s ${MPHP_Path}/sbin/php-fpm ] && [ -s ${MPHP_Path}/etc/php.ini ] && [ -s ${MPHP_Path}/bin/php ]; then
        echo "==========================================="
        Echo_Green "You have successfully install ${Php_Ver} "
        echo "==========================================="
    else
        rm -rf ${MPHP_Path}
        Echo_Red "Failed to install ${Php_Ver}, you can download /root/install-mphp7.0.log from your server, and upload install-mphp7.0.log to LNMP Forum."
    fi
}

Install_MPHP7.1()
{
    lnmp stop

    cd ${cur_dir}/src
    Download_Files ${Download_Mirror}/web/php/${Php_Ver}.tar.bz2 ${Php_Ver}.tar.bz2
    Echo_Blue "[+] Installing ${Php_Ver}"
    Tarj_Cd ${Php_Ver}.tar.bz2 ${Php_Ver}
    ./configure --prefix=${MPHP_Path} --with-config-file-path=${MPHP_Path}/etc --with-config-file-scan-dir=${MPHP_Path}/conf.d --enable-fpm --with-fpm-user=www --with-fpm-group=www --enable-mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv-dir --with-freetype-dir=/usr/local/freetype --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization ${with_curl} --enable-mbregex --enable-mbstring --enable-intl --enable-pcntl --with-mcrypt --enable-ftp --with-gd --enable-gd-native-ttf ${with_openssl} --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --with-gettext ${with_fileinfo} --enable-opcache --with-xsl ${PHP_Modules_Options}

    PHP_Make_Install

    echo "Copy new php configure file..."
    mkdir -p ${MPHP_Path}/{etc,conf.d}
    \cp php.ini-production ${MPHP_Path}/etc/php.ini

    cd ${cur_dir}
    # php extensions
    echo "Modify php.ini......"
    sed -i 's/post_max_size =.*/post_max_size = 50M/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/upload_max_filesize =.*/upload_max_filesize = 50M/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/;date.timezone =.*/date.timezone = PRC/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/short_open_tag =.*/short_open_tag = On/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/;cgi.fix_pathinfo=.*/cgi.fix_pathinfo=0/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/max_execution_time =.*/max_execution_time = 300/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/disable_functions =.*/disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,proc_open,proc_get_status,popen,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server/g' ${MPHP_Path}/etc/php.ini

    echo "Install ZendGuardLoader for PHP 7.1..."
    echo "unavailable now."

    echo "Creating new php-fpm configure file..."
    cat >${MPHP_Path}/etc/php-fpm.conf<<EOF
[global]
pid = ${MPHP_Path}/var/run/php-fpm.pid
error_log = ${MPHP_Path}/var/log/php-fpm.log
log_level = notice

[www]
listen = /tmp/php-cgi7.1.sock
listen.backlog = -1
listen.allowed_clients = 127.0.0.1
listen.owner = www
listen.group = www
listen.mode = 0666
user = www
group = www
pm = dynamic
pm.max_children = 10
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 6
request_terminate_timeout = 100
request_slowlog_timeout = 0
slowlog = var/log/slow.log
EOF

    echo "Copy php-fpm init.d file..."
    \cp ${cur_dir}/src/${Php_Ver}/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm7.1
    chmod +x /etc/init.d/php-fpm7.1

    StartUp php-fpm7.1

    \cp ${cur_dir}/conf/enable-php7.1.conf /usr/local/nginx/conf/enable-php7.1.conf

    sleep 2

    lnmp start

    rm -rf ${cur_dir}/src/${Php_Ver}

    if [ -s ${MPHP_Path}/sbin/php-fpm ] && [ -s ${MPHP_Path}/etc/php.ini ] && [ -s ${MPHP_Path}/bin/php ]; then
        echo "==========================================="
        Echo_Green "You have successfully install ${Php_Ver} "
        echo "==========================================="
    else
        rm -rf ${MPHP_Path}
        Echo_Red "Failed to install ${Php_Ver}, you can download /root/install-mphp7.1.log from your server, and upload install-mphp7.1.log to LNMP Forum."
    fi
}

Install_MPHP7.2()
{
    lnmp stop

    cd ${cur_dir}/src
    Download_Files ${Download_Mirror}/web/php/${Php_Ver}.tar.bz2 ${Php_Ver}.tar.bz2
    Echo_Blue "[+] Installing ${Php_Ver}"
    Tarj_Cd ${Php_Ver}.tar.bz2 ${Php_Ver}
    ./configure --prefix=${MPHP_Path} --with-config-file-path=${MPHP_Path}/etc --with-config-file-scan-dir=${MPHP_Path}/conf.d --enable-fpm --with-fpm-user=www --with-fpm-group=www --enable-mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv-dir --with-freetype-dir=/usr/local/freetype --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization ${with_curl} --enable-mbregex --enable-mbstring --enable-intl --enable-pcntl --enable-ftp --with-gd ${with_openssl} --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --with-gettext ${with_fileinfo} --enable-opcache --with-xsl ${PHP_Modules_Options}

    PHP_Make_Install

    echo "Copy new php configure file..."
    mkdir -p ${MPHP_Path}/{etc,conf.d}
    \cp php.ini-production ${MPHP_Path}/etc/php.ini

    cd ${cur_dir}
    # php extensions
    echo "Modify php.ini......"
    sed -i 's/post_max_size =.*/post_max_size = 50M/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/upload_max_filesize =.*/upload_max_filesize = 50M/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/;date.timezone =.*/date.timezone = PRC/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/short_open_tag =.*/short_open_tag = On/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/;cgi.fix_pathinfo=.*/cgi.fix_pathinfo=0/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/max_execution_time =.*/max_execution_time = 300/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/disable_functions =.*/disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,proc_open,proc_get_status,popen,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server/g' ${MPHP_Path}/etc/php.ini

    echo "Install ZendGuardLoader for PHP 7.2..."
    echo "unavailable now."

    echo "Creating new php-fpm configure file..."
    cat >${MPHP_Path}/etc/php-fpm.conf<<EOF
[global]
pid = ${MPHP_Path}/var/run/php-fpm.pid
error_log = ${MPHP_Path}/var/log/php-fpm.log
log_level = notice

[www]
listen = /tmp/php-cgi7.2.sock
listen.backlog = -1
listen.allowed_clients = 127.0.0.1
listen.owner = www
listen.group = www
listen.mode = 0666
user = www
group = www
pm = dynamic
pm.max_children = 10
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 6
request_terminate_timeout = 100
request_slowlog_timeout = 0
slowlog = var/log/slow.log
EOF

    echo "Copy php-fpm init.d file..."
    \cp ${cur_dir}/src/${Php_Ver}/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm7.2
    chmod +x /etc/init.d/php-fpm7.2

    StartUp php-fpm7.2

    \cp ${cur_dir}/conf/enable-php7.2.conf /usr/local/nginx/conf/enable-php7.2.conf

    sleep 2

    lnmp start

    rm -rf ${cur_dir}/src/${Php_Ver}

    if [ -s ${MPHP_Path}/sbin/php-fpm ] && [ -s ${MPHP_Path}/etc/php.ini ] && [ -s ${MPHP_Path}/bin/php ]; then
        echo "==========================================="
        Echo_Green "You have successfully install ${Php_Ver} "
        echo "==========================================="
    else
        rm -rf ${MPHP_Path}
        Echo_Red "Failed to install ${Php_Ver}, you can download /root/install-mphp7.2.log from your server, and upload install-mphp7.2.log to LNMP Forum."
    fi
}

Install_MPHP7.3()
{
    lnmp stop

    cd ${cur_dir}/src
    Download_Files ${Download_Mirror}/web/php/${Php_Ver}.tar.bz2 ${Php_Ver}.tar.bz2
    Echo_Blue "[+] Installing ${Php_Ver}"
    Tarj_Cd ${Php_Ver}.tar.bz2 ${Php_Ver}
    ./configure --prefix=${MPHP_Path} --with-config-file-path=${MPHP_Path}/etc --with-config-file-scan-dir=${MPHP_Path}/conf.d --enable-fpm --with-fpm-user=www --with-fpm-group=www --enable-mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv-dir --with-freetype-dir=/usr/local/freetype --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization ${with_curl} --enable-mbregex --enable-mbstring --enable-intl --enable-pcntl --enable-ftp --with-gd ${with_openssl} --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --without-libzip --enable-soap --with-gettext ${with_fileinfo} --enable-opcache --with-xsl ${PHP_Modules_Options}

    PHP_Make_Install

    echo "Copy new php configure file..."
    mkdir -p ${MPHP_Path}/{etc,conf.d}
    \cp php.ini-production ${MPHP_Path}/etc/php.ini

    cd ${cur_dir}
    # php extensions
    echo "Modify php.ini......"
    sed -i 's/post_max_size =.*/post_max_size = 50M/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/upload_max_filesize =.*/upload_max_filesize = 50M/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/;date.timezone =.*/date.timezone = PRC/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/short_open_tag =.*/short_open_tag = On/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/;cgi.fix_pathinfo=.*/cgi.fix_pathinfo=0/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/max_execution_time =.*/max_execution_time = 300/g' ${MPHP_Path}/etc/php.ini
    sed -i 's/disable_functions =.*/disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,proc_open,proc_get_status,popen,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server/g' ${MPHP_Path}/etc/php.ini

    echo "Install ZendGuardLoader for PHP 7.3..."
    echo "unavailable now."

    echo "Creating new php-fpm configure file..."
    cat >${MPHP_Path}/etc/php-fpm.conf<<EOF
[global]
pid = ${MPHP_Path}/var/run/php-fpm.pid
error_log = ${MPHP_Path}/var/log/php-fpm.log
log_level = notice

[www]
listen = /tmp/php-cgi7.3.sock
listen.backlog = -1
listen.allowed_clients = 127.0.0.1
listen.owner = www
listen.group = www
listen.mode = 0666
user = www
group = www
pm = dynamic
pm.max_children = 10
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 6
request_terminate_timeout = 100
request_slowlog_timeout = 0
slowlog = var/log/slow.log
EOF

    echo "Copy php-fpm init.d file..."
    \cp ${cur_dir}/src/${Php_Ver}/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm7.3
    chmod +x /etc/init.d/php-fpm7.3

    StartUp php-fpm7.3

    \cp ${cur_dir}/conf/enable-php7.3.conf /usr/local/nginx/conf/enable-php7.3.conf

    sleep 2

    lnmp start

    rm -rf ${cur_dir}/src/${Php_Ver}

    if [ -s ${MPHP_Path}/sbin/php-fpm ] && [ -s ${MPHP_Path}/etc/php.ini ] && [ -s ${MPHP_Path}/bin/php ]; then
        echo "==========================================="
        Echo_Green "You have successfully install ${Php_Ver} "
        echo "==========================================="
    else
        rm -rf ${MPHP_Path}
        Echo_Red "Failed to install ${Php_Ver}, you can download /root/install-mphp7.3.log from your server, and upload install-mphp7.3.log to LNMP Forum."
    fi
}
