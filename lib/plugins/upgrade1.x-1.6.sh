#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script"
    exit 1
fi

cur_dir=$(pwd)
isSSL=$1

. lnmp.conf
. include/main.sh

Get_Dist_Name
Check_Stack
Check_DB

if [ "${isSSL}" == "ssl" ]; then
    echo "+--------------------------------------------------+"
    echo "|  A tool to upgrade lnmp 1.4 certbot to acme.sh   |"
    echo "+--------------------------------------------------+"
    echo "|For more information please visit https://lnmp.org|"
    echo "+--------------------------------------------------+"
    if [[ "${Get_Stack}" =~ "lnmp" ]]; then
        domain=""
        while :;do
            Echo_Yellow "Please enter domain(example: www.lnmp.org): "
            read domain
            if [ "${domain}" != "" ]; then
                if [ ! -f "/usr/local/nginx/conf/vhost/${domain}.conf" ]; then
                    Echo_Red "${domain} is not exist,please check!"
                    exit 1
                else
                    echo " Your domain: ${domain}"
                    if ! grep -q "/etc/letsencrypt/live/${domain}/fullchain.pem" "/usr/local/nginx/conf/vhost/${domain}.conf"; then
                        Echo_Red "SSL configuration NOT found in the ${domain} config file!"
                        exit 1
                    fi
                    break
                fi
            else
                Echo_Red "Domain name can't be empty!"
            fi
        done

        Echo_Yellow "Enter more domain name(example: lnmp.org *.lnmp.org): "
        read moredomain
        if [ "${moredomain}" != "" ]; then
            echo " domain list: ${moredomain}"
        fi

        vhostdir="/home/wwwroot/${domain}"
        echo "Please enter the directory for the domain: $domain"
        Echo_Yellow "Default directory: /home/wwwroot/${domain}: "
        read vhostdir
        if [ "${vhostdir}" == "" ]; then
            vhostdir="/home/wwwroot/${domain}"
        fi
        echo "Virtual Host Directory: ${vhostdir}"

        if [ ! -d "${vhostdir}" ]; then
            Echo_Red "${vhostdir} does not exist or is not a directory!"
            exit 1
        fi

        letsdomain=""
        if [ "${moredomain}" != "" ]; then
            letsdomain="-d ${domain}"
            for i in ${moredomain};do
                letsdomain=${letsdomain}" -d ${i}"
            done
        else
            letsdomain="-d ${domain}"
        fi

        if [ -s /usr/local/acme.sh/acme.sh ]; then
            echo "/usr/local/acme.sh/acme.sh [found]"
        else
            cd /tmp
            [[ -f latest.tar.gz ]] && rm -f latest.tar.gz
            wget https://soft.vpser.net/lib/acme.sh/latest.tar.gz --prefer-family=IPv4 --no-check-certificate
            tar zxf latest.tar.gz
            cd acme.sh-*
            ./acme.sh --install --log --home /usr/local/acme.sh --certhome /usr/local/nginx/conf/ssl
            cd ..
            rm -f latest.tar.gz
            rm -rf acme.sh-*
            sed -i 's/cat "\$CERT_PATH"$/#cat "\$CERT_PATH"/g' /usr/local/acme.sh/acme.sh
        fi

        . "/usr/local/acme.sh/acme.sh.env"

        if [ -s /usr/local/nginx/conf/ssl/${domain}/fullchain.cer ]; then
            echo "Removing exist domain certificate..."
            rm -rf /usr/local/nginx/conf/ssl/${domain}
        fi

        echo "Starting create SSL Certificate use Let's Encrypt..."
        /usr/local/acme.sh/acme.sh --issue ${letsdomain} -w ${vhostdir} --reloadcmd "/etc/init.d/nginx reload"
        lets_status=$?
        if [ "${lets_status}" = 0 ]; then
            Echo_Green "Let's Encrypt SSL Certificate create successfully."
            echo "Modify ${domain} configure..."
            sed -i "s@/etc/letsencrypt/live/${domain}/fullchain.pem@/usr/local/nginx/conf/ssl/${domain}/fullchain.cer@g" "/usr/local/nginx/conf/vhost/${domain}.conf"
            sed -i "s@/etc/letsencrypt/live/${domain}/privkey.pem@/usr/local/nginx/conf/ssl/${domain}/${domain}.key@g" "/usr/local/nginx/conf/vhost/${domain}.conf"
            echo "done."

            if crontab -l|grep -q "/bin/certbot renew"; then
                (crontab -l | grep -v "/bin/certbot renew") | crontab -
            fi

            /etc/init.d/nginx reload
            sleep 1
            Echo_Green "upgrade ${domain} successfully."
        else
            Echo_Red "Let's Encrypt SSL Certificate create failed!"
            Echo_Red "upgrade ${domain} fialed."
        fi
    elif [ "${Get_Stack}" == "lamp" ]; then
        domain=""
        while :;do
            Echo_Yellow "Please enter domain(example: www.lnmp.org): "
            read domain
            if [ "${domain}" != "" ]; then
                if [ ! -f "/usr/local/apache/conf/vhost/${domain}.conf" ]; then
                    Echo_Red "${domain} is not exist,please check!"
                    exit 1
                else
                    echo " Your domain: ${domain}"
                    if ! grep -q "/etc/letsencrypt/live/${domain}/privkey.pem" "/usr/local/apache/conf/vhost/${domain}.conf"; then
                        Echo_Red "SSL configuration NOT found in the ${domain} config file!"
                        exit 1
                    fi
                    break
                fi
            else
                Echo_Red "Domain name can't be empty!"
            fi
        done

        Echo_Yellow "Enter more domain name(example: lnmp.org *.lnmp.org): "
        read moredomain
        if [ "${moredomain}" != "" ]; then
            echo " domain list: ${moredomain}"
        fi

        vhostdir="/home/wwwroot/${domain}"
        echo "Please enter the directory for the domain: $domain"
        Echo_Yellow "Default directory: /home/wwwroot/${domain}: "
        read vhostdir
        if [ "${vhostdir}" == "" ]; then
            vhostdir="/home/wwwroot/${domain}"
        fi
        echo "Virtual Host Directory: ${vhostdir}"

        if [ ! -d "${vhostdir}" ]; then
            Echo_Red "${vhostdir} does not exist or is not a directory!"
            exit 1
        fi

        letsdomain=""
        if [ "${moredomain}" != "" ]; then
            letsdomain="-d ${domain}"
            for i in ${moredomain};do
                letsdomain=${letsdomain}" -d ${i}"
            done
        else
            letsdomain="-d ${domain}"
        fi

        if [ -s /usr/local/acme.sh/acme.sh ]; then
            echo "/usr/local/acme.sh/acme.sh [found]"
        else
            cd /tmp
            [[ -s latest.tar.gz ]] && rm -f latest.tar.gz
            wget https://soft.vpser.net/lib/acme.sh/latest.tar.gz --prefer-family=IPv4 --no-check-certificate
            tar zxf latest.tar.gz
            cd acme.sh-*
            ./acme.sh --install --log --home /usr/local/acme.sh --certhome /usr/local/apache/conf/ssl
            cd ..
            rm -f latest.tar.gz
            rm -rf acme.sh-*
            sed -i 's/cat "\$CERT_PATH"$/#cat "\$CERT_PATH"/g' /usr/local/acme.sh/acme.sh
        fi

        . "/usr/local/acme.sh/acme.sh.env"

        if [ -s /usr/local/apache/conf/ssl/${domain}/fullchain.cer ]; then
            echo "Removing exist domain certificate..."
            rm -rf /usr/local/apache/conf/ssl/${domain}
        fi

        echo "Starting create SSL Certificate use Let's Encrypt..."
        /usr/local/acme.sh/acme.sh --issue ${letsdomain} -w ${vhostdir} --reloadcmd "/etc/init.d/httpd graceful"
        lets_status=$?
        if [ "${lets_status}" = 0 ]; then
            Echo_Green "Let's Encrypt SSL Certificate create successfully."
            echo "Modify ${domain} configure..."
            sed -i "s@/etc/letsencrypt/live/${domain}/fullchain.pem@/usr/local/apache/conf/ssl/${domain}/${domain}.cer@g" "/usr/local/apache/conf/vhost/${domain}.conf"
            sed -i "s@/etc/letsencrypt/live/${domain}/privkey.pem@/usr/local/apache/conf/ssl/${domain}/${domain}.key@g" "/usr/local/apache/conf/vhost/${domain}.conf"
            sed -i "/\/usr\/local\/apache\/conf\/ssl\/${domain}\/${domain}.key/a\SSLCertificateChainFile \/usr\/local\/apache\/conf\/ssl\/${domain}\/ca.cer" "/usr/local/apache/conf/vhost/${domain}.conf"
            echo "done."

            if crontab -l|grep -q "/bin/certbot renew"; then
                (crontab -l | grep -v "/bin/certbot renew") | crontab -
            fi

            /etc/init.d/httpd graceful
            sleep 1
            Echo_Green "upgrade ${domain} successfully."
        else
            Echo_Red "Let's Encrypt SSL Certificate create failed!"
            Echo_Red "upgrade ${domain} fialed."
        fi

    else
        Echo_Red "Can't get stack info and will not be able to upgrade."
    fi
else
    echo "+--------------------------------------------------+"
    echo "|  A tool to upgrade lnmp manager from 1.x to 1.6  |"
    echo "+--------------------------------------------------+"
    echo "|For more information please visit https://lnmp.org|"
    echo "+--------------------------------------------------+"
    Press_Start
    if [ "${Get_Stack}" == "unknow" ]; then
        Echo_Red "Can't get stack info."
        exit
    elif [ "${Get_Stack}" == "lnmp" ]; then
        if [ "$PM" = "yum" ]; then
            Echo_Blue "[+] Yum installing dependent packages..."
            for packages in patch wget crontabs unzip tar ca-certificates net-tools libc-client-devel psmisc libXpm-devel git-core c-ares-devel libicu-devel libxslt libxslt-devel xz expat-devel bzip2 bzip2-devel libaio-devel;
            do yum -y install $packages; done
        elif [ "$PM" = "apt" ]; then
            apt-get update -y
            for packages in debian-keyring debian-archive-keyring build-essential bison libkrb5-dev libcurl3-gnutls libcurl4-gnutls-dev libcurl4-openssl-dev libcap-dev ca-certificates libc-client2007e-dev psmisc patch git libc-ares-dev libicu-dev e2fsprogs libxslt libxslt1-dev libc-client-dev xz-utils libexpat1-dev bzip2 libbz2-dev libaio-dev;
            do apt-get --no-install-recommends install -y $packages; done
        fi
        echo "Copy lnmp manager..."
        sleep 1
        \cp ${cur_dir}/conf/lnmp /bin/lnmp
        chmod +x /bin/lnmp
        echo "Copy configure files..."
        sleep 1
        if [ ! -s /usr/local/nginx/conf/enable-php.conf ]; then
            \cp ${cur_dir}/conf/enable-php.conf /usr/local/nginx/conf/enable-php.conf
        fi
        if [ ! -s /usr/local/nginx/conf/pathinfo.conf ]; then
            \cp ${cur_dir}/conf/pathinfo.conf /usr/local/nginx/conf/pathinfo.conf
        fi
        if [ ! -s /usr/local/nginx/conf/enable-php-pathinfo.conf ]; then
            \cp ${cur_dir}/conf/enable-php-pathinfo.conf /usr/local/nginx/conf/enable-php-pathinfo.conf
        fi
        if [ ! -d /usr/local/nginx/conf/rewrite ]; then
            \cp -ra ${cur_dir}/conf/rewrite /usr/local/nginx/conf/
        fi
        if [ ! -d /usr/local/nginx/conf/vhost ]; then
            mkdir /usr/local/nginx/conf/vhost
        fi
    elif [ "${Get_Stack}" == "lnmpa" ]; then
        echo "Copy lnmp manager..."
        sleep 1
        \cp ${cur_dir}/conf/lnmpa /bin/lnmp
        chmod +x /bin/lnmp
        echo "Copy configure files..."
        sleep 1
        \cp ${cur_dir}/conf/proxy.conf /usr/local/nginx/conf/proxy.conf
        if [ ! -s /usr/local/nginx/conf/proxy-pass-php.conf ]; then
            \cp ${cur_dir}/conf/proxy-pass-php.conf /usr/local/nginx/conf/proxy-pass-php.conf
        fi
        if ! grep -q "SetEnvIf X-Forwarded-Proto https HTTPS=on" /usr/local/apache/conf/httpd.conf; then
            if /usr/local/apache/bin/httpd -v|grep -Eqi "Apache/2.2."; then
                sed -i "/Include conf\/vhost\/\*.conf/i\SetEnvIf X-Forwarded-Proto https HTTPS=on\n" /usr/local/apache/conf/httpd.conf
            elif /usr/local/apache/bin/httpd -v|grep -Eqi "Apache/2.4."; then
                sed -i "/IncludeOptional conf\/vhost\/\*.conf/i\SetEnvIf X-Forwarded-Proto https HTTPS=on\n" /usr/local/apache/conf/httpd.conf
            fi
        fi
        if [ ! -d /usr/local/nginx/conf/vhost ]; then
            mkdir /usr/local/nginx/conf/vhost
        fi
    elif [ "${Get_Stack}" == "lamp" ]; then
        echo "Copy configure files..."
        sleep 1
        \cp ${cur_dir}/conf/lamp /bin/lnmp
        chmod +x /bin/lnmp
        echo "Copy configure files..."
        sleep 1
        if /usr/local/apache/bin/httpd -v|grep -Eqi "Apache/2.2."; then
            \cp ${cur_dir}/conf/httpd22-ssl.conf  /usr/local/apache/conf/extra/httpd-ssl.conf
        elif /usr/local/apache/bin/httpd -v|grep -Eqi "Apache/2.4."; then
            \cp ${cur_dir}/conf/httpd24-ssl.conf  /usr/local/apache/conf/extra/httpd-ssl.conf
            sed -i 's/^#LoadModule socache_shmcb_module/LoadModule socache_shmcb_module/g' /usr/local/apache/conf/httpd.conf
            sed -i 's/^LoadModule lbmethod_heartbeat_module/#LoadModule lbmethod_heartbeat_module/g' /usr/local/apache/conf/httpd.conf
        fi
        if [ ! -d /usr/local/apache/conf/vhost ]; then
            mkdir /usr/local/apache/conf/vhost
        fi
    fi

    if [ "${DB_Name}" = "mariadb" ]; then
        sed -i 's#/etc/init.d/mysql#/etc/init.d/mariadb#' /bin/lnmp
    elif [ "${DB_Name}" = "None" ]; then
        sed -i 's#/etc/init.d/mysql.*##' /bin/lnmp
    fi

    if [ -s /usr/local/acme.sh/acme.sh ]; then
        /usr/local/acme.sh/acme.sh --upgrade
        sed -i 's/cat "\$CERT_PATH"$/#cat "\$CERT_PATH"/g' /usr/local/acme.sh/acme.sh
    fi

    Echo_Green "upgrade lnmp manager complete."
fi