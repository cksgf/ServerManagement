#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script!"
    exit 1
fi

echo "+-------------------------------------------------------------------+"
echo "|   Remove open_basedir restrication for LNMP, Written by Licess    |"
echo "+-------------------------------------------------------------------+"
echo "|       A tool to remove open_basedir restrication for LNMP         |"
echo "+-------------------------------------------------------------------+"
echo "|       For more information please visit https://lnmp.org          |"
echo "+-------------------------------------------------------------------+"
echo "|          Usage: ./remove_open_basedir_restrication.sh             |"
echo "+-------------------------------------------------------------------+"

website_root=''

while :;do
    read -p "Enter website root directory: " website_root
    if [ -d "${website_root}" ]; then
        if [ -f ${website_root}/.user.ini ];then
            chattr -i ${website_root}/.user.ini
            rm -f ${website_root}/.user.ini
            sed -i 's/^fastcgi_param PHP_ADMIN_VALUE/#fastcgi_param PHP_ADMIN_VALUE/g' /usr/local/nginx/conf/fastcgi.conf
            /etc/init.d/php-fpm restart
            /etc/init.d/nginx reload
            echo "done."
        else
            echo "${website_root}/.user.ini is not exist!"
        fi
        break
    else
        echo "${website_root} is not directory or not exist!"
    fi
done