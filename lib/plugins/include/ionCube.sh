#!/bin/bash

Install_ionCube()
{
    echo "====== Installing ionCube ======"
    Press_Start

    rm -f ${PHP_Path}/conf.d/001-ioncube.ini
    Addons_Get_PHP_Ext_Dir
    if echo "${Cur_PHP_Version}" | grep -Eqi '^5.2.'; then
       zend_ext="/usr/local/ioncube/ioncube_loader_lin_5.2.so"
    elif echo "${Cur_PHP_Version}" | grep -Eqi '^5.3.'; then
       zend_ext="/usr/local/ioncube/ioncube_loader_lin_5.3.so"
    elif echo "${Cur_PHP_Version}" | grep -Eqi '^5.4.'; then
       zend_ext="/usr/local/ioncube/ioncube_loader_lin_5.4.so"
    elif echo "${Cur_PHP_Version}" | grep -Eqi '^5.5.'; then
       zend_ext="/usr/local/ioncube/ioncube_loader_lin_5.5.so"
    elif echo "${Cur_PHP_Version}" | grep -Eqi '^5.6.'; then
       zend_ext="/usr/local/ioncube/ioncube_loader_lin_5.6.so"
    elif echo "${Cur_PHP_Version}" | grep -Eqi '^7.0.'; then
       zend_ext="/usr/local/ioncube/ioncube_loader_lin_7.0.so"
    elif echo "${Cur_PHP_Version}" | grep -Eqi '^7.1.'; then
       zend_ext="/usr/local/ioncube/ioncube_loader_lin_7.1.so"
    elif echo "${Cur_PHP_Version}" | grep -Eqi '^7.2.'; then
       zend_ext="/usr/local/ioncube/ioncube_loader_lin_7.2.so"
    else
        Echo_Red "Do not support current PHP version or PHP error!"
        exit 1
    fi

    rm -rf /usr/local/ioncube
    cd ${cur_dir}/src
    rm -rf ioncube
    rm -rf ioncube_loaders_lin_x8*.tar.gz
    if grep -Eqi "xcache.so" ${PHP_Path}/conf.d/006-xcache.ini; then
        if [ "${Is_64bit}" = "y" ] ; then
            Download_Files ${Download_Mirror}/web/ioncube/4.7.5/ioncube_loaders_lin_x86-64.tar.gz ioncube_loaders_lin_x86-64.tar.gz
            tar zxf ioncube_loaders_lin_x86-64.tar.gz
        else
            Download_Files ${Download_Mirror}/web/ioncube/4.7.5/ioncube_loaders_lin_x86.tar.gz ioncube_loaders_lin_x86.tar.gz
            tar zxf ioncube_loaders_lin_x86.tar.gz
        fi
    else
        if [ "${Is_64bit}" = "y" ] ; then
            Download_Files http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz ioncube_loaders_lin_x86-64.tar.gz
            tar zxf ioncube_loaders_lin_x86-64.tar.gz
        else
            Download_Files http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86.tar.gz ioncube_loaders_lin_x86.tar.gz
            tar zxf ioncube_loaders_lin_x86.tar.gz
        fi
    fi
    mv ioncube /usr/local/

    echo "Writing ionCube Loader to configure files..."
    cat >${PHP_Path}/conf.d/001-ioncube.ini<<EOF
[ionCube Loader]
zend_extension="${zend_ext}"
;ioncubeend
EOF

    if [ -s "${zend_ext}" ]; then
        if echo ${zend_ext_dir} | grep -vEqi "non-zts"; then
            sed -i 's/.so/_ts.so/g' ${PHP_Path}/conf.d/001-ioncube.ini
        fi
        Restart_PHP
        Echo_Green "====== ionCube install completed ======"
        Echo_Green "ionCube installed successfully, enjoy it!"
    else
        rm -f ${PHP_Path}/conf.d/001-ioncube.ini
        Echo_Red "ionCube install failed!"
    fi
 }

 Uninstall_ionCube()
 {
    echo "You will uninstall ionCube..."
    Press_Start
    rm -f ${PHP_Path}/conf.d/001-ioncube.ini
    #echo "Delete ionCube files..."
    #rm -rf /usr/local/ioncube/
    Restart_PHP
    Echo_Green "Uninstall ionCube completed."
 }
