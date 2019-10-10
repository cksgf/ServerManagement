#!/bin/bash

Set_Timezone()
{
    Echo_Blue "Setting timezone..."
    rm -rf /etc/localtime
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
}

CentOS_InstallNTP()
{
    Echo_Blue "[+] Installing ntp..."
    yum install -y ntp
    ntpdate -u pool.ntp.org
    date
    start_time=$(date +%s)
}

Deb_InstallNTP()
{
    apt-get update -y
    Echo_Blue "[+] Installing ntp..."
    apt-get install -y ntpdate
    ntpdate -u pool.ntp.org
    date
    start_time=$(date +%s)
}

CentOS_RemoveAMP()
{
    Echo_Blue "[-] Yum remove packages..."
    rpm -qa|grep httpd
    rpm -e httpd httpd-tools --nodeps
    if [[ "${DBSelect}" != "0" ]]; then
        yum -y remove mysql-server mysql mysql-libs mariadb-server mariadb mariadb-libs
        rpm -qa|grep mysql
        if [ $? -ne 0 ]; then
            rpm -e mysql mysql-libs --nodeps
            rpm -e mariadb mariadb-libs --nodeps
        fi
    fi
    rpm -qa|grep php
    rpm -e php-mysql php-cli php-gd php-common php --nodeps

    Remove_Error_Libcurl

    yum -y remove httpd*
    yum -y remove php*
    yum clean all
}

Deb_RemoveAMP()
{
    Echo_Blue "[-] apt-get remove packages..."
    apt-get update -y
    for removepackages in apache2 apache2-doc apache2-utils apache2.2-common apache2.2-bin apache2-mpm-prefork apache2-doc apache2-mpm-worker php5 php5-common php5-cgi php5-cli php5-mysql php5-curl php5-gd;
    do apt-get purge -y $removepackages; done
    if [[ "${DBSelect}" != "0" ]]; then
        for removepackages in mysql-client mysql-server mysql-common mysql-server-core-5.5 mysql-client-5.5 mariadb-client mariadb-server mariadb-common;
        do apt-get purge -y $removepackages; done
        dpkg -l |grep mysql
        dpkg -P mysql-server mysql-common libmysqlclient15off libmysqlclient15-dev
        dpkg -P mariadb-client mariadb-server mariadb-common
    fi
    killall apache2
    dpkg -l |grep apache
    dpkg -P apache2 apache2-doc apache2-mpm-prefork apache2-utils apache2.2-common
    dpkg -l |grep php
    dpkg -P php5 php5-common php5-cli php5-cgi php5-mysql php5-curl php5-gd
    apt-get autoremove -y && apt-get clean
}

Disable_Selinux()
{
    if [ -s /etc/selinux/config ]; then
        sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
    fi
}

Xen_Hwcap_Setting()
{
    if [ -s /etc/ld.so.conf.d/libc6-xen.conf ]; then
        sed -i 's/hwcap 1 nosegneg/hwcap 0 nosegneg/g' /etc/ld.so.conf.d/libc6-xen.conf
    fi
}

Check_Hosts()
{
    if grep -Eqi '^127.0.0.1[[:space:]]*localhost' /etc/hosts; then
        echo "Hosts: ok."
    else
        echo "127.0.0.1 localhost.localdomain localhost" >> /etc/hosts
    fi
    pingresult=`ping -c1 lnmp.org 2>&1`
    echo "${pingresult}"
    if echo "${pingresult}" | grep -q "unknown host"; then
        echo "DNS...fail"
        echo "Writing nameserver to /etc/resolv.conf ..."
        echo -e "nameserver 208.67.220.220\nnameserver 114.114.114.114" > /etc/resolv.conf
    else
        echo "DNS...ok"
    fi
}

RHEL_Modify_Source()
{
    Get_RHEL_Version
    \cp ${cur_dir}/conf/CentOS-Base-163.repo /etc/yum.repos.d/CentOS-Base-163.repo
    sed -i "s/\$releasever/${RHEL_Ver}/g" /etc/yum.repos.d/CentOS-Base-163.repo
    sed -i "s/RPM-GPG-KEY-CentOS-6/RPM-GPG-KEY-CentOS-${RHEL_Ver}/g" /etc/yum.repos.d/CentOS-Base-163.repo
    yum clean all
    yum makecache
}

Ubuntu_Modify_Source()
{
    if [ "${country}" = "CN" ]; then
        OldReleasesURL='http://mirrors.ustc.edu.cn/ubuntu-old-releases/ubuntu/'
    else
        OldReleasesURL='http://old-releases.ubuntu.com/ubuntu/'
    fi
    CodeName=''
    if grep -Eqi "10.10" /etc/*-release || echo "${Ubuntu_Version}" | grep -Eqi '^10.10'; then
        CodeName='maverick'
    elif grep -Eqi "11.04" /etc/*-release || echo "${Ubuntu_Version}" | grep -Eqi '^11.04'; then
        CodeName='natty'
    elif  grep -Eqi "11.10" /etc/*-release || echo "${Ubuntu_Version}" | grep -Eqi '^11.10'; then
        CodeName='oneiric'
    elif grep -Eqi "12.10" /etc/*-release || echo "${Ubuntu_Version}" | grep -Eqi '^12.10'; then
        CodeName='quantal'
    elif grep -Eqi "13.04" /etc/*-release || echo "${Ubuntu_Version}" | grep -Eqi '^13.04'; then
        CodeName='raring'
    elif grep -Eqi "13.10" /etc/*-release || echo "${Ubuntu_Version}" | grep -Eqi '^13.10'; then
        CodeName='saucy'
    elif grep -Eqi "10.04" /etc/*-release || echo "${Ubuntu_Version}" | grep -Eqi '^10.04'; then
        CodeName='lucid'
    elif grep -Eqi "14.10" /etc/*-release || echo "${Ubuntu_Version}" | grep -Eqi '^14.10'; then
        CodeName='utopic'
    elif grep -Eqi "15.04" /etc/*-release || echo "${Ubuntu_Version}" | grep -Eqi '^15.04'; then
        CodeName='vivid'
    elif grep -Eqi "12.04" /etc/*-release || echo "${Ubuntu_Version}" | grep -Eqi '^12.04'; then
        CodeName='precise'
    elif grep -Eqi "15.10" /etc/*-release || echo "${Ubuntu_Version}" | grep -Eqi '^15.10'; then
        CodeName='wily'
    elif grep -Eqi "16.10" /etc/*-release || echo "${Ubuntu_Version}" | grep -Eqi '^16.10'; then
        CodeName='yakkety'
    elif grep -Eqi "14.04" /etc/*-release || echo "${Ubuntu_Version}" | grep -Eqi '^14.04'; then
        Ubuntu_Deadline trusty
    elif grep -Eqi "17.04" /etc/*-release || echo "${Ubuntu_Version}" | grep -Eqi '^17.04'; then
        CodeName='zesty'
    elif grep -Eqi "17.10" /etc/*-release || echo "${Ubuntu_Version}" | grep -Eqi '^17.10'; then
        Ubuntu_Deadline artful
    elif grep -Eqi "16.04" /etc/*-release || echo "${Ubuntu_Version}" | grep -Eqi '^16.04'; then
        Ubuntu_Deadline xenial
    elif grep -Eqi "18.10" /etc/*-release || echo "${Ubuntu_Version}" | grep -Eqi '^18.10'; then
        Ubuntu_Deadline cosmic
    fi
    if [ "${CodeName}" != "" ]; then
        \cp /etc/apt/sources.list /etc/apt/sources.list.$(date +"%Y%m%d")
        cat > /etc/apt/sources.list<<EOF
deb ${OldReleasesURL} ${CodeName} main restricted universe multiverse
deb ${OldReleasesURL} ${CodeName}-security main restricted universe multiverse
deb ${OldReleasesURL} ${CodeName}-updates main restricted universe multiverse
deb ${OldReleasesURL} ${CodeName}-proposed main restricted universe multiverse
deb ${OldReleasesURL} ${CodeName}-backports main restricted universe multiverse
deb-src ${OldReleasesURL} ${CodeName} main restricted universe multiverse
deb-src ${OldReleasesURL} ${CodeName}-security main restricted universe multiverse
deb-src ${OldReleasesURL} ${CodeName}-updates main restricted universe multiverse
deb-src ${OldReleasesURL} ${CodeName}-proposed main restricted universe multiverse
deb-src ${OldReleasesURL} ${CodeName}-backports main restricted universe multiverse
EOF
    fi
}

Check_Old_Releases_URL()
{
    OR_Status=`wget --spider --server-response ${OldReleasesURL}/dists/$1/Release 2>&1 | awk '/^  HTTP/{print $2}'`
    if [ ${OR_Status} != "404" ]; then
        echo "Ubuntu old-releases status: ${OR_Status}";
        CodeName=$1
    fi
}

Ubuntu_Deadline()
{
    trusty_deadline=`date -d "2019-7-22 00:00:00" +%s`
    artful_deadline=`date -d "2018-7-31 00:00:00" +%s`
    xenial_deadline=`date -d "2021-4-30 00:00:00" +%s`
    cosmic_deadline=`date -d "2019-7-30 00:00:00" +%s`
    cur_time=`date  +%s`
    case "$1" in
        trusty)
            if [ ${cur_time} -gt ${trusty_deadline} ]; then
                echo "${cur_time} > ${trusty_deadline}"
                Check_Old_Releases_URL trusty
            fi
            ;;
        artful)
            if [ ${cur_time} -gt ${artful_deadline} ]; then
                echo "${cur_time} > ${artful_deadline}"
                Check_Old_Releases_URL artful
            fi
            ;;
        xenial)
            if [ ${cur_time} -gt ${xenial_deadline} ]; then
                echo "${cur_time} > ${xenial_deadline}"
                Check_Old_Releases_URL xenial
            fi
            ;;
        cosmic)
            if [ ${cur_time} -gt ${cosmic_deadline} ]; then
                echo "${cur_time} > ${cosmic_deadline}"
                Check_Old_Releases_URL cosmic
            fi
            ;;
    esac
}

CentOS_Dependent()
{
    if [ -s /etc/yum.conf ]; then
        \cp /etc/yum.conf /etc/yum.conf.lnmp
        sed -i 's:exclude=.*:exclude=:g' /etc/yum.conf
    fi

    Echo_Blue "[+] Yum installing dependent packages..."
    for packages in make cmake gcc gcc-c++ gcc-g77 flex bison file libtool libtool-libs autoconf kernel-devel patch wget crontabs libjpeg libjpeg-devel libpng libpng-devel libpng10 libpng10-devel gd gd-devel libxml2 libxml2-devel zlib zlib-devel glib2 glib2-devel unzip tar bzip2 bzip2-devel libzip-devel libevent libevent-devel ncurses ncurses-devel curl curl-devel libcurl libcurl-devel e2fsprogs e2fsprogs-devel krb5 krb5-devel libidn libidn-devel openssl openssl-devel vim-minimal gettext gettext-devel ncurses-devel gmp-devel pspell-devel unzip libcap diffutils ca-certificates net-tools libc-client-devel psmisc libXpm-devel git-core c-ares-devel libicu-devel libxslt libxslt-devel xz expat-devel libaio-devel rpcgen libtirpc-devel perl python-devel cyrus-sasl-devel;
    do yum -y install $packages; done

    if [ -s /etc/yum.conf.lnmp ]; then
        mv -f /etc/yum.conf.lnmp /etc/yum.conf
    fi
}

Deb_Dependent()
{
    Echo_Blue "[+] Apt-get installing dependent packages..."
    apt-get update -y
    apt-get autoremove -y
    apt-get -fy install
    export DEBIAN_FRONTEND=noninteractive
    apt-get --no-install-recommends install -y build-essential gcc g++ make
    for packages in debian-keyring debian-archive-keyring build-essential gcc g++ make cmake autoconf automake re2c wget cron bzip2 libzip-dev libc6-dev bison file rcconf flex vim bison m4 gawk less cpp binutils diffutils unzip tar bzip2 libbz2-dev libncurses5 libncurses5-dev libtool libevent-dev openssl libssl-dev zlibc libsasl2-dev libltdl3-dev libltdl-dev zlib1g zlib1g-dev libbz2-1.0 libbz2-dev libglib2.0-0 libglib2.0-dev libpng3 libjpeg-dev libpng-dev libpng12-0 libpng12-dev libkrb5-dev curl libcurl3-gnutls libcurl4-gnutls-dev libcurl4-openssl-dev libpq-dev libpq5 gettext libpng12-dev libxml2-dev libcap-dev ca-certificates libc-client2007e-dev psmisc patch git libc-ares-dev libicu-dev e2fsprogs libxslt libxslt1-dev libc-client-dev xz-utils libexpat1-dev libaio-dev libtirpc-dev python-dev;
    do apt-get --no-install-recommends install -y $packages; done
}

Check_Download()
{
    Echo_Blue "[+] Downloading files..."
    cd ${cur_dir}/src
    Download_Files ${Download_Mirror}/web/libiconv/${Libiconv_Ver}.tar.gz ${Libiconv_Ver}.tar.gz
    Download_Files ${Download_Mirror}/web/libmcrypt/${LibMcrypt_Ver}.tar.gz ${LibMcrypt_Ver}.tar.gz
    Download_Files ${Download_Mirror}/web/mcrypt/${Mcypt_Ver}.tar.gz ${Mcypt_Ver}.tar.gz
    Download_Files ${Download_Mirror}/web/mhash/${Mhash_Ver}.tar.bz2 ${Mhash_Ver}.tar.bz2
    if [ "${SelectMalloc}" = "2" ]; then
        Download_Files ${Download_Mirror}/lib/jemalloc/${Jemalloc_Ver}.tar.bz2 ${Jemalloc_Ver}.tar.bz2
    elif [ "${SelectMalloc}" = "3" ]; then
        Download_Files ${Download_Mirror}/lib/tcmalloc/${TCMalloc_Ver}.tar.gz ${TCMalloc_Ver}.tar.gz
        Download_Files ${Download_Mirror}/lib/libunwind/${Libunwind_Ver}.tar.gz ${Libunwind_Ver}.tar.gz
    fi
    if [ "${Stack}" != "lamp" ]; then
        Download_Files ${Download_Mirror}/web/nginx/${Nginx_Ver}.tar.gz ${Nginx_Ver}.tar.gz
    fi
    if [[ "${DBSelect}" =~ ^[12345]$ ]]; then
        Download_Files ${Download_Mirror}/datebase/mysql/${Mysql_Ver}.tar.gz ${Mysql_Ver}.tar.gz
    elif [[ "${DBSelect}" =~ ^[6789]|10$ ]]; then
        Download_Files ${Download_Mirror}/datebase/mariadb/${Mariadb_Ver}.tar.gz ${Mariadb_Ver}.tar.gz
    fi
    Download_Files ${Download_Mirror}/web/php/${Php_Ver}.tar.bz2 ${Php_Ver}.tar.bz2
    if [ ${PHPSelect} = "1" ]; then
        Download_Files ${Download_Mirror}/web/phpfpm/${Php_Ver}-fpm-0.5.14.diff.gz ${Php_Ver}-fpm-0.5.14.diff.gz
    fi
    Download_Files ${Download_Mirror}/datebase/phpmyadmin/${PhpMyAdmin_Ver}.tar.xz ${PhpMyAdmin_Ver}.tar.xz
    Download_Files ${Download_Mirror}/prober/p.tar.gz p.tar.gz
    if [ "${Stack}" != "lnmp" ]; then
        Download_Files ${Download_Mirror}/web/apache/${Apache_Ver}.tar.bz2 ${Apache_Ver}.tar.bz2
        Download_Files ${Download_Mirror}/web/apache/${APR_Ver}.tar.bz2 ${APR_Ver}.tar.bz2
        Download_Files ${Download_Mirror}/web/apache/${APR_Util_Ver}.tar.bz2 ${APR_Util_Ver}.tar.bz2
    fi
    Download_Files ${Download_Mirror}/lib/openssl/${Openssl_Ver}.tar.gz ${Openssl_Ver}.tar.gz
}

Make_Install()
{
    make -j `grep 'processor' /proc/cpuinfo | wc -l`
    if [ $? -ne 0 ]; then
        make
    fi
    make install
}

PHP_Make_Install()
{
    make ZEND_EXTRA_LIBS='-liconv' -j `grep 'processor' /proc/cpuinfo | wc -l`
    if [ $? -ne 0 ]; then
        make ZEND_EXTRA_LIBS='-liconv'
    fi
    make install
}

Install_Autoconf()
{
    Echo_Blue "[+] Installing ${Autoconf_Ver}"
    cd ${cur_dir}/src
    Download_Files ${Download_Mirror}/lib/autoconf/${Autoconf_Ver}.tar.gz ${Autoconf_Ver}.tar.gz
    Tar_Cd ${Autoconf_Ver}.tar.gz ${Autoconf_Ver}
    ./configure --prefix=/usr/local/autoconf-2.13
    Make_Install
    cd ${cur_dir}/src/
    rm -rf ${cur_dir}/src/${Autoconf_Ver}
}

Install_Libiconv()
{
    Echo_Blue "[+] Installing ${Libiconv_Ver}"
    Tar_Cd ${Libiconv_Ver}.tar.gz ${Libiconv_Ver}
    ./configure --enable-static
    Make_Install
    cd ${cur_dir}/src/
    rm -rf ${cur_dir}/src/${Libiconv_Ver}
}

Install_Libmcrypt()
{
    Echo_Blue "[+] Installing ${LibMcrypt_Ver}"
    Tar_Cd ${LibMcrypt_Ver}.tar.gz ${LibMcrypt_Ver}
    ./configure
    Make_Install
    /sbin/ldconfig
    cd libltdl/
    ./configure --enable-ltdl-install
    Make_Install
    ln -sf /usr/local/lib/libmcrypt.la /usr/lib/libmcrypt.la
    ln -sf /usr/local/lib/libmcrypt.so /usr/lib/libmcrypt.so
    ln -sf /usr/local/lib/libmcrypt.so.4 /usr/lib/libmcrypt.so.4
    ln -sf /usr/local/lib/libmcrypt.so.4.4.8 /usr/lib/libmcrypt.so.4.4.8
    ldconfig
    cd ${cur_dir}/src/
    rm -rf ${cur_dir}/src/${LibMcrypt_Ver}
}

Install_Mcrypt()
{
    Echo_Blue "[+] Installing ${Mcypt_Ver}"
    Tar_Cd ${Mcypt_Ver}.tar.gz ${Mcypt_Ver}
    ./configure
    Make_Install
    cd ${cur_dir}/src/
    rm -rf ${cur_dir}/src/${Mcypt_Ver}
}

Install_Mhash()
{
    Echo_Blue "[+] Installing ${Mhash_Ver}"
    Tarj_Cd ${Mhash_Ver}.tar.bz2 ${Mhash_Ver}
    ./configure
    Make_Install
    ln -sf /usr/local/lib/libmhash.a /usr/lib/libmhash.a
    ln -sf /usr/local/lib/libmhash.la /usr/lib/libmhash.la
    ln -sf /usr/local/lib/libmhash.so /usr/lib/libmhash.so
    ln -sf /usr/local/lib/libmhash.so.2 /usr/lib/libmhash.so.2
    ln -sf /usr/local/lib/libmhash.so.2.0.1 /usr/lib/libmhash.so.2.0.1
    ldconfig
    cd ${cur_dir}/src/
    rm -rf ${cur_dir}/src/${Mhash_Ver}
}

Install_Freetype()
{
    if echo "${Ubuntu_Version}" | grep -Eqi "1[89]\." || echo "${Mint_Version}" | grep -Eqi "19\." || echo "${Deepin_Version}" | grep -Eqi "15\.[7-9]" || echo "${Debian_Version}" | grep -Eqi "9\."; then
        Download_Files ${Download_Mirror}/lib/freetype/${Freetype_New_Ver}.tar.bz2 ${Freetype_New_Ver}.tar.bz2
        Echo_Blue "[+] Installing ${Freetype_New_Ver}"
        Tarj_Cd ${Freetype_New_Ver}.tar.bz2 ${Freetype_New_Ver}
        ./configure --prefix=/usr/local/freetype --enable-freetype-config
    else
        Download_Files ${Download_Mirror}/lib/freetype/${Freetype_Ver}.tar.bz2 ${Freetype_Ver}.tar.bz2
        Echo_Blue "[+] Installing ${Freetype_Ver}"
        Tarj_Cd ${Freetype_Ver}.tar.bz2 ${Freetype_Ver}
        ./configure --prefix=/usr/local/freetype
    fi
    Make_Install

    [[ -d /usr/lib/pkgconfig ]] && \cp /usr/local/freetype/lib/pkgconfig/freetype2.pc /usr/lib/pkgconfig/
    cat > /etc/ld.so.conf.d/freetype.conf<<EOF
/usr/local/freetype/lib
EOF
    ldconfig
    ln -sf /usr/local/freetype/include/freetype2/* /usr/include/
    cd ${cur_dir}/src/
    rm -rf ${cur_dir}/src/${Freetype_Ver}
}

Install_Curl()
{
    if [[ ! -s /usr/local/curl/bin/curl || ! -s /usr/local/curl/lib/libcurl.so || ! -s /usr/local/curl/include/curl/curl.h ]]; then
        Echo_Blue "[+] Installing ${Curl_Ver}"
        cd ${cur_dir}/src
        Download_Files ${Download_Mirror}/lib/curl/${Curl_Ver}.tar.bz2 ${Curl_Ver}.tar.bz2
        Tarj_Cd ${Curl_Ver}.tar.bz2 ${Curl_Ver}
        ./configure --prefix=/usr/local/curl --enable-ares --without-nss --with-ssl
        Make_Install
        cd ${cur_dir}/src/
        rm -rf ${cur_dir}/src/${Curl_Ver}
    fi
    Remove_Error_Libcurl
}

Install_Pcre()
{
    if [ ! -s /usr/bin/pcre-config ] || /usr/bin/pcre-config --version | grep -vEqi '^8.'; then
        Echo_Blue "[+] Installing ${Pcre_Ver}"
        cd ${cur_dir}/src
        Download_Files ${Download_Mirror}/web/pcre/${Pcre_Ver}.tar.bz2 ${Pcre_Ver}.tar.bz2
        Tarj_Cd ${Pcre_Ver}.tar.bz2 ${Pcre_Ver}
        ./configure
        Make_Install
        cd ${cur_dir}/src/
        rm -rf ${cur_dir}/src/${Pcre_Ver}
    fi
}

Install_Jemalloc()
{
    Echo_Blue "[+] Installing ${Jemalloc_Ver}"
    cd ${cur_dir}/src
    Tarj_Cd ${Jemalloc_Ver}.tar.bz2 ${Jemalloc_Ver}
    ./configure
    Make_Install
    ldconfig
    cd ${cur_dir}/src/
    rm -rf ${cur_dir}/src/${Jemalloc_Ver}
    ln -sf /usr/local/lib/libjemalloc* /usr/lib/
}

Install_TCMalloc()
{
    Echo_Blue "[+] Installing ${TCMalloc_Ver}"
    if [ "${Is_64bit}" = "y" ]; then
        Tar_Cd ${Libunwind_Ver}.tar.gz ${Libunwind_Ver}
        CFLAGS=-fPIC ./configure
        make CFLAGS=-fPIC
        make CFLAGS=-fPIC install
        rm -rf ${cur_dir}/src/${Libunwind_Ver}
    fi
    Tar_Cd ${TCMalloc_Ver}.tar.gz ${TCMalloc_Ver}
    if [ "${Is_64bit}" = "y" ]; then
        ./configure
    else
        ./configure --enable-frame-pointers
    fi
    Make_Install
    ldconfig
    cd ${cur_dir}/src/
    rm -rf ${cur_dir}/src/${TCMalloc_Ver}
    ln -sf /usr/local/lib/libtcmalloc* /usr/lib/
}

Install_Icu4c()
{
    if [ ! -s /usr/bin/icu-config ] || /usr/bin/icu-config --version | grep '^3.'; then
        Echo_Blue "[+] Installing ${Libicu4c_Ver}"
        cd ${cur_dir}/src
        Download_Files ${Download_Mirror}/lib/icu4c/${Libicu4c_Ver}-src.tgz ${Libicu4c_Ver}-src.tgz
        Tar_Cd ${Libicu4c_Ver}-src.tgz icu/source
        ./configure --prefix=/usr
        Make_Install
        cd ${cur_dir}/src/
        rm -rf ${cur_dir}/src/icu
    fi
}

Install_Boost()
{
    Echo_Blue "[+] Download or use exist boost..."
    if [ "${DBSelect}" = "4" ] || echo "${mysql_version}" | grep -Eqi '^5.7.'; then
        if [ -s "${cur_dir}/src/${Boost_Ver}.tar.bz2" ]; then
            [[ -d "${cur_dir}/src/${Boost_Ver}" ]] && rm -rf "${cur_dir}/src/${Boost_Ver}"
            tar jxf ${cur_dir}/src/${Boost_Ver}.tar.bz2 -C ${cur_dir}/src
            MySQL_WITH_BOOST="-DWITH_BOOST=${cur_dir}/src/${Boost_Ver}"
        else
            MySQL_WITH_BOOST="-DDOWNLOAD_BOOST=1 -DWITH_BOOST=${cur_dir}/src"
        fi
    elif [ "${DBSelect}" = "5" ] || echo "${mysql_version}" | grep -Eqi '^8.0.'; then
        Get_Boost_Ver=$(grep 'SET(BOOST_PACKAGE_NAME' cmake/boost.cmake |grep -oP '\d+(\_\d+){2}')
        if [ -s "${cur_dir}/src/boost_${Get_Boost_Ver}.tar.bz2" ]; then
            [[ -d "${cur_dir}/src/boost_${Get_Boost_Ver}" ]] && rm -rf "${cur_dir}/src/boost_${Get_Boost_Ver}"
            tar jxf ${cur_dir}/src/boost_${Get_Boost_Ver}.tar.bz2 -C ${cur_dir}/src
            MySQL_WITH_BOOST="-DWITH_BOOST=${cur_dir}/src/boost_${Get_Boost_Ver}"
        else
            MySQL_WITH_BOOST="-DDOWNLOAD_BOOST=1 -DWITH_BOOST=${cur_dir}/src"
        fi
    fi
}

Install_Openssl()
{
    if [ ! -s /usr/local/openssl/bin/openssl ] || /usr/local/openssl/bin/openssl version | grep -v 'OpenSSL 1.0.2'; then
        Echo_Blue "[+] Installing ${Openssl_Ver}"
        cd ${cur_dir}/src
        Download_Files ${Download_Mirror}/lib/openssl/${Openssl_Ver}.tar.gz ${Openssl_Ver}.tar.gz
        [[ -d "${Openssl_Ver}" ]] && rm -rf ${Openssl_Ver}
        Tar_Cd ${Openssl_Ver}.tar.gz ${Openssl_Ver}
        ./config -fPIC --prefix=/usr/local/openssl --openssldir=/usr/local/openssl
        make depend
        Make_Install
        cd ${cur_dir}/src/
        rm -rf ${cur_dir}/src/${Openssl_Ver}
    fi
}

Install_Openssl_New()
{
        Echo_Blue "[+] Installing ${Openssl_New_Ver}"
        cd ${cur_dir}/src
        Download_Files ${Download_Mirror}/lib/openssl/${Openssl_New_Ver}.tar.gz ${Openssl_New_Ver}.tar.gz
        [[ -d "${Openssl_New_Ver}" ]] && rm -rf ${Openssl_New_Ver}
        Tar_Cd ${Openssl_New_Ver}.tar.gz ${Openssl_New_Ver}
        ./config enable-weak-ssl-ciphers -fPIC --prefix=/usr/local/openssl --openssldir=/usr/local/openssl
        make depend
        Make_Install
        ln -sf /usr/local/openssl/lib/libcrypto.so.1.1 /usr/lib/
        ln -sf /usr/local/openssl/lib/libssl.so.1.1 /usr/lib/
        cd ${cur_dir}/src/
        rm -rf ${cur_dir}/src/${Openssl_New_Ver}
        ldconfig
}

Install_Nghttp2()
{
    if [[ ! -s /usr/local/nghttp2/lib/libnghttp2.so || ! -s /usr/local/nghttp2/include/nghttp2/nghttp2.h ]]; then
        Echo_Blue "[+] Installing ${Nghttp2_Ver}"
        cd ${cur_dir}/src
        Download_Files ${Download_Mirror}/lib/nghttp2/${Nghttp2_Ver}.tar.xz ${Nghttp2_Ver}.tar.xz
        [[ -d "${Nghttp2_Ver}" ]] && rm -rf ${Nghttp2_Ver}
        tar Jxf ${Nghttp2_Ver}.tar.xz && cd ${Nghttp2_Ver}
        ./configure --prefix=/usr/local/nghttp2
        Make_Install
        cd ${cur_dir}/src/
        rm -rf ${cur_dir}/src/${Nghttp2_Ver}
    fi
}

CentOS_Lib_Opt()
{
    if [ "${Is_64bit}" = "y" ] ; then
        ln -sf /usr/lib64/libpng.* /usr/lib/
        ln -sf /usr/lib64/libjpeg.* /usr/lib/
    fi

    ulimit -v unlimited

    if [ `grep -L "/lib"    '/etc/ld.so.conf'` ]; then
        echo "/lib" >> /etc/ld.so.conf
    fi

    if [ `grep -L '/usr/lib'    '/etc/ld.so.conf'` ]; then
        echo "/usr/lib" >> /etc/ld.so.conf
        #echo "/usr/lib/openssl/engines" >> /etc/ld.so.conf
    fi

    if [ -d "/usr/lib64" ] && [ `grep -L '/usr/lib64'    '/etc/ld.so.conf'` ]; then
        echo "/usr/lib64" >> /etc/ld.so.conf
        #echo "/usr/lib64/openssl/engines" >> /etc/ld.so.conf
    fi

    if [ `grep -L '/usr/local/lib'    '/etc/ld.so.conf'` ]; then
        echo "/usr/local/lib" >> /etc/ld.so.conf
    fi

    ldconfig

    cat >>/etc/security/limits.conf<<eof
* soft nproc 65535
* hard nproc 65535
* soft nofile 65535
* hard nofile 65535
eof

    echo "fs.file-max=65535" >> /etc/sysctl.conf
}

Deb_Lib_Opt()
{
    if [ "${Is_64bit}" = "y" ]; then
        ln -sf /usr/lib/x86_64-linux-gnu/libpng* /usr/lib/
        ln -sf /usr/lib/x86_64-linux-gnu/libjpeg* /usr/lib/
    else
        ln -sf /usr/lib/i386-linux-gnu/libpng* /usr/lib/
        ln -sf /usr/lib/i386-linux-gnu/libjpeg* /usr/lib/
        ln -sf /usr/include/i386-linux-gnu/asm /usr/include/asm
    fi

    if [ -d "/usr/lib/arm-linux-gnueabihf" ]; then
        ln -sf /usr/lib/arm-linux-gnueabihf/libpng* /usr/lib/
        ln -sf /usr/lib/arm-linux-gnueabihf/libjpeg* /usr/lib/
        ln -sf /usr/include/arm-linux-gnueabihf/curl /usr/include/
    fi

    ulimit -v unlimited

    if [ `grep -L "/lib"    '/etc/ld.so.conf'` ]; then
        echo "/lib" >> /etc/ld.so.conf
    fi

    if [ `grep -L '/usr/lib'    '/etc/ld.so.conf'` ]; then
        echo "/usr/lib" >> /etc/ld.so.conf
    fi

    if [ -d "/usr/lib64" ] && [ `grep -L '/usr/lib64'    '/etc/ld.so.conf'` ]; then
        echo "/usr/lib64" >> /etc/ld.so.conf
    fi

    if [ `grep -L '/usr/local/lib'    '/etc/ld.so.conf'` ]; then
        echo "/usr/local/lib" >> /etc/ld.so.conf
    fi

    if [ -d /usr/include/x86_64-linux-gnu/curl ]; then
        ln -sf /usr/include/x86_64-linux-gnu/curl /usr/include/
    elif [ -d /usr/include/i386-linux-gnu/curl ]; then
        ln -sf /usr/include/i386-linux-gnu/curl /usr/include/
    fi

    if [ -d /usr/include/arm-linux-gnueabihf/curl ]; then
        ln -sf /usr/include/arm-linux-gnueabihf/curl /usr/include/
    fi

    if [ -d /usr/include/aarch64-linux-gnu/curl ]; then
        ln -sf /usr/include/aarch64-linux-gnu/curl /usr/include/
    fi

    ldconfig

    cat >>/etc/security/limits.conf<<eof
* soft nproc 65535
* hard nproc 65535
* soft nofile 65535
* hard nofile 65535
eof

    echo "fs.file-max=65535" >> /etc/sysctl.conf
}

Remove_Error_Libcurl()
{
    if [ -s /usr/local/lib/libcurl.so ]; then
        rm -f /usr/local/lib/libcurl*
    fi
}

Add_Swap()
{
    Swap_Total=$(free -m | grep Swap | awk '{print  $2}')
    if [[ "${Enable_Swap}" = "y" && "${Swap_Total}" = "0" ]]; then
        echo "Add Swap file..."
        if [ "${MemTotal}" -lt 1024 ]; then
            DD_Count='1024'
        elif [[ "${MemTotal}" -ge 1024 && "${MemTotal}" -le 2048 ]]; then
            DD_Count='2028'
        fi
        dd if=/dev/zero of=/var/swapfile bs=1M count=${DD_Count}
        chmod 0600 /var/swapfile
        echo "Enable Swap..."
        /sbin/mkswap /var/swapfile
        /sbin/swapon /var/swapfile
        if [ $? -eq 0 ]; then
            [ `grep -L '/var/swapfile'    '/etc/fstab'` ] && echo "/var/swapfile swap swap defaults 0 0" >>/etc/fstab
            /sbin/swapon -s
        else
            rm -f /var/swapfile
            echo "Add Swap Failed!"
        fi
    fi
}
