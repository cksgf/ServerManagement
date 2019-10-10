#!/bin/bash

Install_Opcache()
{

    Echo_Red "Install Opcache will auto uninstall eAccelerator if exists..."
    echo "====== Installing zend opcache ======"
    Press_Start

    echo "Uninstall eAccelerator..."
    rm -f ${PHP_Path}/conf.d/004-opcache.ini

    Addons_Get_PHP_Ext_Dir
    zend_ext="${zend_ext_dir}opcache.so"
    if echo "${Cur_PHP_Version}" | grep -Eqi '^5.[234].'; then
        if [ -s "${zend_ext}" ]; then
            rm -f "${zend_ext}"
        fi
    fi

    if echo "${Cur_PHP_Version}" | grep -Eqi '^5.2.'; then
        echo "Zend Opcache do NOT SUPPORT PHP 5.2.* and lower version of php 5.3"
        sleep 1
        exit 1
    elif echo "${Cur_PHP_Version}" | grep -Eqi '^5.3.'; then
        if echo ${Cur_PHP_Version} | grep -vEqi '^5.3.2[0-9]';then
            echo "If PHP under version 5.3.20, we do not recommend install opcache, it maybe cause 502 Bad Gateway error!"
            sleep 3
            exit 1
        fi
    elif echo "${Cur_PHP_Version}" | grep -Eqi '^5.4.'; then
        echo "${Cur_PHP_Version}"
    elif echo "${Cur_PHP_Version}" | grep -Eqi '^5.[56].' || echo "${Cur_PHP_Version}" | grep -Eqi '^7.'; then
        cat >${PHP_Path}/conf.d/004-opcache.ini<<EOF
[Zend Opcache]
zend_extension="opcache.so"
opcache.memory_consumption=128
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=4000
opcache.revalidate_freq=60
opcache.fast_shutdown=1
opcache.enable_cli=1
EOF

        echo "Copy Opcache Control Panel..."
        \cp ${cur_dir}/conf/ocp.php ${Default_Website_Dir}/ocp.php
        Restart_PHP
        if [ -s "${zend_ext}" ]; then
            Echo_Green "====== Opcache install completed ======"
            Echo_Green "Opcache installed successfully, enjoy it!"
            exit 0
        else
            rm -f ${PHP_Path}/conf.d/004-opcache.ini
            Echo_Red "OPcache install failed!"
            exit 1
        fi
    else
        echo "Error: can't get php version!"
        echo "Maybe php was didn't install or php configuration file has errors.Please check."
        sleep 3
        exit 1
    fi

    cd ${cur_dir}/src

    if [ -d "${ZendOpcache_Ver}" ]; then
        rm -rf "${ZendOpcache_Ver}"
    fi

    Download_Files ${Download_Mirror}/web/opcache/${ZendOpcache_Ver}.tgz ${ZendOpcache_Ver}.tgz
    Tar_Cd ${ZendOpcache_Ver}.tgz ${ZendOpcache_Ver}
    ${PHP_Path}/bin/phpize
    ./configure --with-php-config=${PHP_Path}/bin/php-config
    make
    make install
    cd ../

    cat >${PHP_Path}/conf.d/004-opcache.ini<<EOF
[Zend Opcache]
zend_extension="opcache.so"
opcache.memory_consumption=128
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=4000
opcache.revalidate_freq=60
opcache.fast_shutdown=1
opcache.enable_cli=1
EOF

    echo "Copy Opcache Control Panel..."
    \cp $cur_dir/conf/ocp.php ${Default_Website_Dir}/ocp.php

    Restart_PHP

    if [ -s "${zend_ext}" ]; then
        echo "====== Opcache install completed ======"
        echo "Opcache installed successfully, enjoy it!"
    else
        rm -f ${PHP_Path}/conf.d/004-opcache.ini
        echo "OPcache install failed!"
    fi
}

Uninstall_Opcache()
{
    echo "You will uninstall opcache..."
    Press_Start
    rm -f ${PHP_Path}/conf.d/004-opcache.ini
    Restart_PHP
    Echo_Green "Uninstall Opcache completed."
}
