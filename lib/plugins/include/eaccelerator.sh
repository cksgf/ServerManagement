#!/bin/bash

#Install eaccelerator 0.9.5.3
Install_Old_eA()
{
    if [ -s eaccelerator-0.9.5.3 ]; then
        rm -rf eaccelerator-0.9.5.3/
    fi

    if echo "${Cur_PHP_Version}" | grep -Eqi '^5.[345].';then
        echo "PHP 5.3.* and higher version Can't install eaccelerator 0.9.5.3!"
        echo "PHP 5.3.* please enter 2 or 3 !"
        echo "PHP 5.4.* please enter 3 !"
        exit 1
    fi

    Download_Files ${Download_Mirror}/web/eaccelerator/eaccelerator-0.9.5.3.tar.bz2 eaccelerator-0.9.5.3.tar.bz2
    Tarj_Cd eaccelerator-0.9.5.3.tar.bz2 eaccelerator-0.9.5.3
    ${PHP_Path}/bin/phpize
    ./configure --enable-eaccelerator=shared --with-php-config=${PHP_Path}/bin/php-config --with-eaccelerator-shared-memory
    make
    make install
    cd ../
}

#Install eaccelerator 0.9.6.1
Install_New_eA()
{
    if [ -s eaccelerator-0.9.6.1 ]; then
        rm -rf eaccelerator-0.9.6.1/
    fi

    if echo "${Cur_PHP_Version}" | grep -Eqi '^5.[456].';then
        echo "PHP 5.4.* and higher version Can't install eaccelerator 0.9.6.1!"
        exit 1
    fi

    Download_Files ${Download_Mirror}/web/eaccelerator/eaccelerator-0.9.6.1.tar.bz2 eaccelerator-0.9.6.1.tar.bz2
    Tarj_Cd eaccelerator-0.9.6.1.tar.bz2 eaccelerator-0.9.6.1
    ${PHP_Path}/bin/phpize
    ./configure --enable-eaccelerator=shared --with-php-config=${PHP_Path}/bin/php-config
    make
    make install
    cd ../
}

#Install eaccelerator git master branch 42067ac
Install_Dev_eA()
{
    if [ -s eaccelerator-eaccelerator-42067ac ]; then
        rm -rf eaccelerator-eaccelerator-42067ac/
    fi

    if echo "${Cur_PHP_Version}" | grep -Eqi '^5.[56].';then
        echo "PHP 5.5.* and higher version do not support eaccelerator!"
        exit 1
    fi

    Download_Files ${Download_Mirror}/web/eaccelerator/eaccelerator-eaccelerator-42067ac.tar.gz eaccelerator-eaccelerator-42067ac.tar.gz
    Tar_Cd eaccelerator-eaccelerator-42067ac.tar.gz eaccelerator-eaccelerator-42067ac
    ${PHP_Path}/bin/phpize
    ./configure --enable-eaccelerator=shared --with-php-config=${PHP_Path}/bin/php-config
    make
    make install
    cd ../
}

Install_eAccelerator()
{
    ver="3"
    echo "Which version do you want to install:"
    echo "Install eaccelerator 0.9.5.3 please enter: 1"
    echo "Install eaccelerator 0.9.6.1 please enter: 2"
    echo "Install eaccelerator 1.0-dev please enter: 3"
    read -p "Enter 1, 2 or 3 (Default version 3): " ver
    if [ "${ver}" = "" ]; then
        ver="3"
    fi

    if [ "${ver}" = "1" ]; then
        echo "You will install eaccelerator 0.9.5.3"
    elif  [ "${ver}" = "2" ]; then
        echo "You will install eaccelerator 0.9.6.1"
    elif [ "${ver}" = "3" ]; then
        echo "You will install eaccelerator 1.0-dev"
    else
        echo "Input error,please input 1, 2 or 3 !"
        echo "Please Rerun $0"
        exit 1
    fi

    echo "====== Installing eAccelerator ======"
    Press_Start

    rm -f ${PHP_Path}/conf.d/001-eaccelerator.ini
    Addons_Get_PHP_Ext_Dir
    zend_ext="${zend_ext_dir}eaccelerator.so"
    if [ -s "${zend_ext}" ]; then
        rm -f "${zend_ext}"
    fi
    if echo "${Cur_PHP_Version}" | grep -vEqi '^5.[2345].';then
        Echo_Red "Error: Current PHP Version can't install eAccelerator."
        Echo_Red "Maybe php was didn't install or php configuration file has errors.Please check."
        sleep 3
        exit 1
    fi

    cd ${cur_dir}/src
    if [ "${ver}" = "1" ]; then
        Install_Old_eA
    elif [ "${ver}" = "2" ]; then
        Install_New_eA
    else
        Install_Dev_eA
    fi

    mkdir -p /usr/local/eaccelerator_cache
    rm -rf /usr/local/eaccelerator_cache/*

    cat >${PHP_Path}/conf.d/001-eaccelerator.ini<<EOF
[eaccelerator]
zend_extension="${zend_ext}"
eaccelerator.shm_size="1"
eaccelerator.cache_dir="/usr/local/eaccelerator_cache"
eaccelerator.enable="1"
eaccelerator.optimizer="1"
eaccelerator.check_mtime="1"
eaccelerator.debug="0"
eaccelerator.filter=""
eaccelerator.shm_max="0"
eaccelerator.shm_ttl="3600"
eaccelerator.shm_prune_period="3600"
eaccelerator.shm_only="0"
eaccelerator.compress="1"
eaccelerator.compress_level="9"
eaccelerator.keys = "disk_only"
eaccelerator.sessions = "disk_only"
eaccelerator.content = "disk_only"
EOF

    if [ -s "${zend_ext}" ]; then
        Restart_PHP
        Echo_Green "====== eAccelerator install completed ======"
        Echo_Green "eAccelerator installed successfully, enjoy it!"
    else
        rm -f ${PHP_Path}/conf.d/001-eaccelerator.ini
        Echo_Red "eAccelerator install failed!"
    fi
}

Uninstall_eAccelerator()
{
    echo "You will uninstall eAccelerator..."
    Press_Start
    rm -f ${PHP_Path}/conf.d/001-eaccelerator.ini
    echo "Delete eaccelerator_cache directory..."
    rm -rf /usr/local/eaccelerator_cache
    Restart_PHP
    Echo_Green "Uninstall eAccelerator completed."
}
