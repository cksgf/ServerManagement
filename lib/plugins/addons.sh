#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script"
    exit 1
fi

cur_dir=$(pwd)
action=$1
action2=$2

. lnmp.conf
. include/main.sh
. include/init.sh
. include/version.sh
. include/eaccelerator.sh
. include/xcache.sh
. include/memcached.sh
. include/opcache.sh
. include/redis.sh
. include/imageMagick.sh
. include/ionCube.sh
. include/apcu.sh

Display_Addons_Menu()
{
    echo "##### cache / optimizer / accelerator #####"
    echo "1: eAccelerator"
    echo "2: XCache"
    echo "3: Memcached"
    echo "4: opcache"
    echo "5: Redis"
    echo "6: apcu"
    echo "##### Image Processing #####"
    echo "7: imageMagick"
    echo "##### encryption/decryption utility for PHP #####"
    echo "8: ionCube Loader"
    echo "exit: Exit current script"
    echo "#####################################################"
    read -p "Enter your choice (1, 2, 3, 4, 5, 6, 7, 8 or exit): " action2
}

Restart_PHP()
{
    if [ -s /usr/local/apache/bin/httpd ] && [ -s /usr/local/apache/conf/httpd.conf ] && [ -s /etc/init.d/httpd ]; then
        echo "Restarting Apache......"
        /etc/init.d/httpd restart
    else
        echo "Restarting php-fpm......"
        ${PHPFPM_Initd} restart
    fi
}

clear
echo "+-----------------------------------------------------------------------+"
echo "|            Addons script for LNMP V1.4, Written by Licess             |"
echo "+-----------------------------------------------------------------------+"
echo "|    A tool to Install cache,optimizer,accelerator...addons for LNMP    |"
echo "+-----------------------------------------------------------------------+"
echo "|           For more information please visit https://lnmp.org          |"
echo "+-----------------------------------------------------------------------+"

Select_PHP()
{
    if [[ ! -s /usr/local/php5.2/sbin/php-fpm && ! -s /usr/local/nginx/conf/enable-php5.2.conf ]] && [[ ! -s /usr/local/php5.3/sbin/php-fpm && ! -s /usr/local/nginx/conf/enable-php5.3.conf ]] && [[ ! -s /usr/local/php5.4/sbin/php-fpm && ! -s /usr/local/nginx/conf/enable-php5.4.conf ]] && [[ ! -s /usr/local/php5.5/sbin/php-fpm && ! -s /usr/local/nginx/conf/enable-php5.5.conf ]] && [[ ! -s /usr/local/php5.6/sbin/php-fpm && ! -s /usr/local/nginx/conf/enable-php5.6.conf ]] && [[ ! -s /usr/local/php7.0/sbin/php-fpm && ! -s /usr/local/nginx/conf/enable-php7.0.conf ]] && [[ ! -s /usr/local/php7.1/sbin/php-fpm && ! -s /usr/local/nginx/conf/enable-php7.1.conf ]] && [[ ! -s /usr/local/php7.2/sbin/php-fpm && ! -s /usr/local/nginx/conf/enable-php7.2.conf ]]; then
        PHP_Path='/usr/local/php'
        PHPFPM_Initd='/etc/init.d/php-fpm'
    else
        echo "Multiple PHP version found, Please select the PHP version."
        Cur_PHP_Version="`/usr/local/php/bin/php-config --version`"
        Echo_Green "1: Default Main PHP ${Cur_PHP_Version}"
        if [[ -s /usr/local/php5.2/sbin/php-fpm && -s /usr/local/nginx/conf/enable-php5.2.conf && -s /etc/init.d/php-fpm5.2 ]]; then
            Echo_Green "2: PHP 5.2 [found]"
        fi
        if [[ -s /usr/local/php5.3/sbin/php-fpm && -s /usr/local/nginx/conf/enable-php5.3.conf && -s /etc/init.d/php-fpm5.3 ]]; then
            Echo_Green "3: PHP 5.3 [found]"
        fi
        if [[ -s /usr/local/php5.4/sbin/php-fpm && -s /usr/local/nginx/conf/enable-php5.4.conf && -s /etc/init.d/php-fpm5.4 ]]; then
            Echo_Green "4: PHP 5.4 [found]"
        fi
        if [[ -s /usr/local/php5.5/sbin/php-fpm && -s /usr/local/nginx/conf/enable-php5.5.conf && -s /etc/init.d/php-fpm5.5 ]]; then
            Echo_Green "5: PHP 5.5 [found]"
        fi
        if [[ -s /usr/local/php5.6/sbin/php-fpm && -s /usr/local/nginx/conf/enable-php5.6.conf && -s /etc/init.d/php-fpm5.6 ]]; then
            Echo_Green "6: PHP 5.6 [found]"
        fi
        if [[ -s /usr/local/php7.0/sbin/php-fpm && -s /usr/local/nginx/conf/enable-php7.0.conf && -s /etc/init.d/php-fpm7.0 ]]; then
            Echo_Green "7: PHP 7.0 [found]"
        fi
        if [[ -s /usr/local/php7.1/sbin/php-fpm && -s /usr/local/nginx/conf/enable-php7.1.conf && -s /etc/init.d/php-fpm7.1 ]]; then
            Echo_Green "8: PHP 7.1 [found]"
        fi
        if [[ -s /usr/local/php7.2/sbin/php-fpm && -s /usr/local/nginx/conf/enable-php7.2.conf && -s /etc/init.d/php-fpm7.2 ]]; then
            Echo_Green "9: PHP 7.2 [found]"
        fi
        Echo_Yellow "Enter your choice (1, 2, 3, 4, 5, 6 ,7 or 8): "
        read php_select
        case "${php_select}" in
            1)
                echo "Current selection: PHP ${Cur_PHP_Version}"
                PHP_Path='/usr/local/php'
                PHPFPM_Initd='/etc/init.d/php-fpm'
                ;;
            2)
                echo "Current selection: PHP `/usr/local/php5.2/bin/php-config --version`"
                PHP_Path='/usr/local/php5.2'
                PHPFPM_Initd='/etc/init.d/php-fpm5.2'
                ;;
            3)
                echo "Current selection: PHP `/usr/local/php5.3/bin/php-config --version`"
                PHP_Path='/usr/local/php5.3'
                PHPFPM_Initd='/etc/init.d/php-fpm5.3'
                ;;
            4)
                echo "Current selection: PHP `/usr/local/php5.4/bin/php-config --version`"
                PHP_Path='/usr/local/php5.4'
                PHPFPM_Initd='/etc/init.d/php-fpm5.4'
                ;;
            5)
                echo "Current selection: PHP `/usr/local/php5.5/bin/php-config --version`"
                PHP_Path='/usr/local/php5.5'
                PHPFPM_Initd='/etc/init.d/php-fpm5.5'
                ;;
            6)
                echo "Current selection: PHP `/usr/local/php5.6/bin/php-config --version`"
                PHP_Path='/usr/local/php5.6'
                PHPFPM_Initd='/etc/init.d/php-fpm5.6'
                ;;
            7)
                echo "Current selection:: PHP `/usr/local/php7.0/bin/php-config --version`"
                PHP_Path='/usr/local/php7.0'
                PHPFPM_Initd='/etc/init.d/php-fpm7.0'
                ;;
            8)
                echo "Current selection:: PHP `/usr/local/php7.1/bin/php-config --version`"
                PHP_Path='/usr/local/php7.1'
                PHPFPM_Initd='/etc/init.d/php-fpm7.1'
                ;;
            9)
                echo "Current selection:: PHP `/usr/local/php7.2/bin/php-config --version`"
                PHP_Path='/usr/local/php7.2'
                PHPFPM_Initd='/etc/init.d/php-fpm7.2'
                ;;
            *)
                echo "Default,Current selection: PHP ${Cur_PHP_Version}"
                php_select="1"
                PHP_Path='/usr/local/php'
                PHPFPM_Initd='/etc/init.d/php-fpm'
                ;;
        esac
    fi
}

Addons_Get_PHP_Ext_Dir()
{
    Cur_PHP_Version="`${PHP_Path}/bin/php-config --version`"
    zend_ext_dir="`${PHP_Path}/bin/php-config --extension-dir`/"
}

if [[ "${action}" == "" || "${action2}" == "" ]]; then
    action='install'
    Display_Addons_Menu
fi
Get_Dist_Name
Select_PHP

    case "${action}" in
    install)
        case "${action2}" in
            1|e[aA]ccelerator)
                Install_eAccelerator
                ;;
            2|[xX]cache)
                Install_XCache
                ;;
            3|[mM]emcached)
                Install_Memcached
                ;;
            4|opcache)
                Install_Opcache
                ;;
            5|[rR]edis)
                Install_Redis
                ;;
            6|apcu)
                Install_Apcu
                ;;
            7|image[mM]agick)
                Install_ImageMagic
                ;;
            8|ion[cC]ube)
                Install_ionCube
                ;;
            [eE][xX][iI][tT])
                exit 1
                ;;
            *)
                echo "Usage: ./addons.sh {install|uninstall} {eaccelerator|xcache|memcached|opcache|redis|imagemagick|ioncube}"
                ;;
        esac
        ;;
    uninstall)
        case "${action2}" in
            e[aA]ccelerator)
                Uninstall_eAccelerator
                ;;
            [xX]cache)
                Uninstall_XCache
                ;;
            [mM]emcached)
                Uninstall_Memcached
                ;;
            opcache)
                Uninstall_Opcache
                ;;
            [rR]edis)
                Uninstall_Redis
                ;;
            apcu)
                Uninstall_Apcu
                ;;
            image[mM]agick)
                Uninstall_ImageMagick
                ;;
            ion[cC]ube)
                Uninstall_ionCube
                ;;
            *)
                echo "Usage: ./addons.sh {install|uninstall} {eaccelerator|xcache|memcached|opcache|redis|apcu|imagemagick|ioncube}"
                ;;
        esac
        ;;
    [eE][xX][iI][tT])
        exit 1
        ;;
    *)
        echo "Usage: ./addons.sh {install|uninstall} {eaccelerator|xcache|memcached|opcache|redis|apcu|imagemagick|ioncube}"
        exit 1
        ;;
    esac
