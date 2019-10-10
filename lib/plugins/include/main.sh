#!/bin/bash

DB_Info=('MySQL 5.1.73' 'MySQL 5.5.62' 'MySQL 5.6.42' 'MySQL 5.7.24' 'MySQL 8.0.13' 'MariaDB 5.5.62' 'MariaDB 10.0.37' 'MariaDB 10.1.37' 'MariaDB 10.2.19' 'MariaDB 10.3.11')
PHP_Info=('PHP 5.2.17' 'PHP 5.3.29' 'PHP 5.4.45' 'PHP 5.5.38' 'PHP 5.6.40' 'PHP 7.0.33' 'PHP 7.1.26' 'PHP 7.2.14' 'PHP 7.3.1')
Apache_Info=('Apache 2.2.34' 'Apache 2.4.37')

Database_Selection()
{
#which MySQL Version do you want to install?
    DBSelect=$(cat /home/lnmpconfig/DBSelect)
    case "${DBSelect}" in
    1)
        echo "You will install ${DB_Info[0]}"
        ;;
    2)
        echo "You will install ${DB_Info[1]}"
        ;;
    3)
        echo "You will Install ${DB_Info[2]}"
        ;;
    4)
        echo "You will install ${DB_Info[3]}"
        ;;
    5)
        echo "You will install ${DB_Info[4]}"
        ;;
    6)
        echo "You will install ${DB_Info[5]}"
        ;;
    7)
        echo "You will install ${DB_Info[6]}"
        ;;
    8)
        echo "You will install ${DB_Info[7]}"
        ;;
    9)
        echo "You will install ${DB_Info[8]}"
        ;;
    10)
        echo "You will install ${DB_Info[9]}"
        ;;
    0)
        echo "Do not install MySQL/MariaDB!"
        ;;
    *)
        echo "No input,You will install ${DB_Info[1]}"
        DBSelect="2"
    esac

    if [[ "${DBSelect}" =~ ^[345789]|10$ ]] && [ `free -m | grep Mem | awk '{print  $2}'` -le 1024 ]; then
        echo "Memory less than 1GB, can't install MySQL 5.6+ or MairaDB 10+!"
        exit 1
    fi

    if [[ "${DBSelect}" =~ ^[6789]|10$ ]]; then
        MySQL_Bin="/usr/local/mariadb/bin/mysql"
        MySQL_Config="/usr/local/mariadb/bin/mysql_config"
        MySQL_Dir="/usr/local/mariadb"
    elif [[ "${DBSelect}" =~ ^[12345]$ ]]; then
        MySQL_Bin="/usr/local/mysql/bin/mysql"
        MySQL_Config="/usr/local/mysql/bin/mysql_config"
        MySQL_Dir="/usr/local/mysql"
    fi

    if [[ "${DBSelect}" != "0" ]]; then
        #set mysql root password
        DB_Root_Password=$(cat /home/lnmpconfig/DBPWD)
        echo "MySQL root password: ${DB_Root_Password}"
        #do you want to enable or disable the InnoDB Storage Engine?
        echo "==========================="
        InstallInnodb="y"
        case "${InstallInnodb}" in
        [yY][eE][sS]|[yY])
            echo "You will enable the InnoDB Storage Engine"
            InstallInnodb="y"
            ;;
        [nN][oO]|[nN])
            echo "You will disable the InnoDB Storage Engine!"
            InstallInnodb="n"
            ;;
        *)
            echo "No input,The InnoDB Storage Engine will enable."
            InstallInnodb="y"
        esac
    fi
}

PHP_Selection()
{
#which PHP Version do you want to install?
    PHPSelect=$(cat /home/lnmpconfig/PHPVERSION)
    case "${PHPSelect}" in
    1)
        echo "You will install ${PHP_Info[0]}"
        if [[ "${DBSelect}" = 0 ]]; then
            echo "You didn't select MySQL/MariaDB can't select ${PHP_Info[0]}!"
            exit 1
        fi
        ;;
    2)
        echo "You will install ${PHP_Info[1]}"
        ;;
    3)
        echo "You will Install ${PHP_Info[2]}"
        ;;
    4)
        echo "You will install ${PHP_Info[3]}"
        ;;
    5)
        echo "You will install ${PHP_Info[4]}"
        ;;
    6)
        echo "You will install ${PHP_Info[5]}"
        ;;
    7)
        echo "You will install ${PHP_Info[6]}"
        ;;
    8)
        echo "You will install ${PHP_Info[7]}"
        ;;
    9)
        echo "You will install ${PHP_Info[8]}"
        ;;
    *)
        echo "No input,You will install ${PHP_Info[4]}"
        PHPSelect="5"
    esac
}

MemoryAllocator_Selection()
{
#which Memory Allocator do you want to install?
    SelectMalloc="3"

    case "${SelectMalloc}" in
    1)
        echo "You will install not install Memory Allocator."
        ;;
    2)
        echo "You will install JeMalloc"
        ;;
    3)
        echo "You will Install TCMalloc"
        ;;
    *)
        echo "No input,You will not install Memory Allocator."
        SelectMalloc="1"
    esac

    if [ "${SelectMalloc}" =  "1" ]; then
        MySQL51MAOpt=''
        MySQLMAOpt=''
        NginxMAOpt=''
    elif [ "${SelectMalloc}" =  "2" ]; then
        MySQL51MAOpt='--with-mysqld-ldflags=-ljemalloc'
        MySQLMAOpt='[mysqld_safe]
malloc-lib=/usr/lib/libjemalloc.so'
        NginxMAOpt="--with-ld-opt='-ljemalloc'"
    elif [ "${SelectMalloc}" =  "3" ]; then
        MySQL51MAOpt='--with-mysqld-ldflags=-ltcmalloc'
        MySQLMAOpt='[mysqld_safe]
malloc-lib=/usr/lib/libtcmalloc.so'
        NginxMAOpt='--with-google_perftools_module'
    fi
}

Dispaly_Selection()
{
    Database_Selection
    PHP_Selection
    MemoryAllocator_Selection
}

Apache_Selection()
{
    echo "==========================="
    #set Server Administrator Email Address
    ServerAdmin=$(cat /home/lnmpconfig/ApacheEmail)

#which Apache Version do you want to install?
    ApacheSelect=$(cat /home/lnmpconfig/ApacheVERSION)

    if [ "${ApacheSelect}" = "1" ]; then
        echo "You will install ${Apache_Info[0]}"
    elif [ "${ApacheSelect}" = "2" ]; then
        echo "You will install ${Apache_Info[1]}"
    else
        echo "No input,You will install ${Apache_Info[1]}"
        ApacheSelect="2"
    fi
    if [[ "${PHPSelect}" = "1" && "${ApacheSelect}" = "2" ]]; then
        Echo_Red "PHP 5.2.17 is not compatible with Apache 2.4.*."
        Echo_Red "Force use Apache 2.2.31"
        ApacheSelect="1"
    fi
}

Kill_PM()
{
    if ps aux | grep "yum" | grep -qv "grep"; then
        if [ -s /usr/bin/killall ]; then
            killall yum
        else
            kill `pidof yum`
        fi
    elif ps aux | grep "apt-get" | grep -qv "grep"; then
        if [ -s /usr/bin/killall ]; then
            killall apt-get
        else
            kill `pidof apt-get`
        fi
    fi
}

Press_Install()
{
    . include/version.sh
    Kill_PM
}

Press_Start()
{
    echo ""
}

Install_LSB()
{
    echo "[+] Installing lsb..."
    if [ "$PM" = "yum" ]; then
        yum -y install redhat-lsb
    elif [ "$PM" = "apt" ]; then
        apt-get update
        apt-get --no-install-recommends install -y lsb-release
    fi
}

Get_Dist_Version()
{
    if [ -s /usr/bin/python3 ]; then
        eval ${DISTRO}_Version=`/usr/bin/python3 -c 'import platform; print(platform.linux_distribution()[1])'`
    elif [ -s /usr/bin/python2 ]; then
        eval ${DISTRO}_Version=`/usr/bin/python2 -c 'import platform; print platform.linux_distribution()[1]'`
    fi
    if [ $? -ne 0 ]; then
        Install_LSB
        eval ${DISTRO}_Version=`lsb_release -rs`
    fi
}

Get_Dist_Name()
{
    if grep -Eqi "CentOS" /etc/issue || grep -Eq "CentOS" /etc/*-release; then
        DISTRO='CentOS'
        PM='yum'
    elif grep -Eqi "Red Hat Enterprise Linux Server" /etc/issue || grep -Eq "Red Hat Enterprise Linux Server" /etc/*-release; then
        DISTRO='RHEL'
        PM='yum'
    elif grep -Eqi "Aliyun" /etc/issue || grep -Eq "Aliyun" /etc/*-release; then
        DISTRO='Aliyun'
        PM='yum'
    elif grep -Eqi "Fedora" /etc/issue || grep -Eq "Fedora" /etc/*-release; then
        DISTRO='Fedora'
        PM='yum'
    elif grep -Eqi "Amazon Linux" /etc/issue || grep -Eq "Amazon Linux" /etc/*-release; then
        DISTRO='Amazon'
        PM='yum'
    elif grep -Eqi "Debian" /etc/issue || grep -Eq "Debian" /etc/*-release; then
        DISTRO='Debian'
        PM='apt'
    elif grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release; then
        DISTRO='Ubuntu'
        PM='apt'
    elif grep -Eqi "Raspbian" /etc/issue || grep -Eq "Raspbian" /etc/*-release; then
        DISTRO='Raspbian'
        PM='apt'
    elif grep -Eqi "Deepin" /etc/issue || grep -Eq "Deepin" /etc/*-release; then
        DISTRO='Deepin'
        PM='apt'
    elif grep -Eqi "Mint" /etc/issue || grep -Eq "Mint" /etc/*-release; then
        DISTRO='Mint'
        PM='apt'
    elif grep -Eqi "Kali" /etc/issue || grep -Eq "Kali" /etc/*-release; then
        DISTRO='Kali'
        PM='apt'
    else
        DISTRO='unknow'
    fi
    Get_OS_Bit
}

Get_RHEL_Version()
{
    Get_Dist_Name
    if [ "${DISTRO}" = "RHEL" ]; then
        if grep -Eqi "release 5." /etc/redhat-release; then
            echo "Current Version: RHEL Ver 5"
            RHEL_Ver='5'
        elif grep -Eqi "release 6." /etc/redhat-release; then
            echo "Current Version: RHEL Ver 6"
            RHEL_Ver='6'
        elif grep -Eqi "release 7." /etc/redhat-release; then
            echo "Current Version: RHEL Ver 7"
            RHEL_Ver='7'
        fi
    fi
}

Get_OS_Bit()
{
    if [[ `getconf WORD_BIT` = '32' && `getconf LONG_BIT` = '64' ]] ; then
        Is_64bit='y'
    else
        Is_64bit='n'
    fi
}

Get_ARM()
{
    if uname -m | grep -Eqi "arm|aarch64"; then
        Is_ARM='y'
    fi
}

Download_Files()
{
    local URL=$1
    local FileName=$2
    if [ -s "${FileName}" ]; then
        echo "${FileName} [found]"
    else
        echo "Notice: ${FileName} not found!!!download now..."
        wget -c --progress=bar:force --prefer-family=IPv4 --no-check-certificate ${URL}
    fi
}

Tar_Cd()
{
    local FileName=$1
    local DirName=$2
    cd ${cur_dir}/src
    [[ -d "${DirName}" ]] && rm -rf ${DirName}
    echo "Uncompress ${FileName}..."
    tar zxf ${FileName}
    if [ -n "${DirName}" ]; then
        echo "cd ${DirName}..."
        cd ${DirName}
    fi
}

Tarj_Cd()
{
    local FileName=$1
    local DirName=$2
    cd ${cur_dir}/src
    [[ -d "${DirName}" ]] && rm -rf ${DirName}
    echo "Uncompress ${FileName}..."
    tar jxf ${FileName}
    if [ -n "${DirName}" ]; then
        echo "cd ${DirName}..."
        cd ${DirName}
    fi
}

Check_LNMPConf()
{
    if [ ! -s "${cur_dir}/lnmp.conf" ]; then
        Echo_Red "lnmp.conf was not exsit!"
        exit 1
    fi
    if [[ "${Download_Mirror}" = "" || "${MySQL_Data_Dir}" = "" || "${MariaDB_Data_Dir}" = "" || "${Default_Website_Dir}" = "" ]]; then
        Echo_Red "Can't get values from lnmp.conf!"
        exit 1
    fi
    if [[ "${MySQL_Data_Dir}" = "/" || "${MariaDB_Data_Dir}" = "/" || "${Default_Website_Dir}" = "/" ]]; then
        Echo_Red "Can't set MySQL/MariaDB/Website Directory to / !"
        exit 1
    fi
}

Print_APP_Ver()
{
    echo "You will install ${Stack} stack."
    if [ "${Stack}" != "lamp" ]; then
        echo "${Nginx_Ver}"
    fi

    if [[ "${DBSelect}" =~ ^[12345]$ ]]; then
        echo "${Mysql_Ver}"
    elif [[ "${DBSelect}" =~ ^[6789]|10$ ]]; then
        echo "${Mariadb_Ver}"
    elif [ "${DBSelect}" = "0" ]; then
        echo "Do not install MySQL/MariaDB!"
    fi

    echo "${Php_Ver}"

    if [ "${Stack}" != "lnmp" ]; then
        echo "${Apache_Ver}"
    fi

    if [ "${SelectMalloc}" = "2" ]; then
        echo "${Jemalloc_Ver}"
    elif [ "${SelectMalloc}" = "3" ]; then
        echo "${TCMalloc_Ver}"
    fi
    echo "Enable InnoDB: ${InstallInnodb}"
    echo "Print lnmp.conf infomation..."
    echo "Download Mirror: ${Download_Mirror}"
    echo "Nginx Additional Modules: ${Nginx_Modules_Options}"
    echo "PHP Additional Modules: ${PHP_Modules_Options}"
    if [ "${Enable_PHP_Fileinfo}" = "y" ]; then
        echo "enable PHP fileinfo."
    fi
    if [ "${Enable_Nginx_Lua}" = "y" ]; then
        echo "enable Nginx Lua."
    fi
    if [[ "${DBSelect}" =~ ^[12345]$ ]]; then
        echo "Database Directory: ${MySQL_Data_Dir}"
    elif [[ "${DBSelect}" =~ ^[6789]|10$ ]]; then
        echo "Database Directory: ${MariaDB_Data_Dir}"
    elif [ "${DBSelect}" = "0" ]; then
        echo "Do not install MySQL/MariaDB!"
    fi
    echo "Default Website Directory: ${Default_Website_Dir}"
}

Print_Sys_Info()
{
    echo "LNMP Version: ${LNMP_Ver}"
    eval echo "${DISTRO} \${${DISTRO}_Version}"
    cat /etc/issue
    cat /etc/*-release
    uname -a
    MemTotal=`free -m | grep Mem | awk '{print  $2}'`
    echo "Memory is: ${MemTotal} MB "
    df -h
    openssl version
}

StartUp()
{
    init_name=$1
    echo "Add ${init_name} service at system startup..."
    if [ "$PM" = "yum" ]; then
        chkconfig --add ${init_name}
        chkconfig ${init_name} on
    elif [ "$PM" = "apt" ]; then
        update-rc.d -f ${init_name} defaults
    fi
}

Remove_StartUp()
{
    init_name=$1
    echo "Removing ${init_name} service at system startup..."
    if [ "$PM" = "yum" ]; then
        chkconfig ${init_name} off
        chkconfig --del ${init_name}
    elif [ "$PM" = "apt" ]; then
        update-rc.d -f ${init_name} remove
    fi
}

Check_Mirror()
{
    if [ ! -s /usr/bin/curl ]; then
        if [ "$PM" = "yum" ]; then
            yum install -y curl
        elif [ "$PM" = "apt" ]; then
            apt-get update
            apt-get install -y curl
        fi
    fi
    country=`curl -sSk --connect-timeout 30 -m 60 https://ip.vpser.net/country`
    echo "Server Location: ${country}"
    if [ "${Download_Mirror}" = "https://soft.vpser.net" ]; then
        echo "Try http://soft.vpser.net ..."
        mirror_code=`curl -o /dev/null -m 20 --connect-timeout 20 -sk -w %{http_code} http://soft.vpser.net`
        if [[ "${mirror_code}" = "200" || "${mirror_code}" = "302" ]]; then
            echo "http://soft.vpser.net http code: ${mirror_code}"
            ping -c 3 soft.vpser.net
        else
            ping -c 3 soft.vpser.net
            if [ "${country}" = "CN" ]; then
                echo "Try http://soft1.vpser.net ..."
                mirror_code=`curl -o /dev/null -m 20 --connect-timeout 20 -sk -w %{http_code} http://soft1.vpser.net`
                if [[ "${mirror_code}" = "200" || "${mirror_code}" = "302" ]]; then
                    echo "Change to mirror http://soft1.vpser.net"
                    Download_Mirror='http://soft1.vpser.net'
                else
                    echo "Try http://soft2.vpser.net ..."
                    mirror_code=`curl -o /dev/null -m 20 --connect-timeout 20 -sk -w %{http_code} http://soft2.vpser.net`
                    if [[ "${mirror_code}" = "200" || "${mirror_code}" = "302" ]]; then
                        echo "Change to mirror http://soft2.vpser.net"
                        Download_Mirror='http://soft2.vpser.net'
                    else
                        echo "Can not connect to download mirror,Please modify lnmp.conf manually."
                        echo "More info,please visit https://lnmp.org/faq/download-url.html"
                        exit 1
                    fi
                fi
            else
                echo "Try http://soft2.vpser.net ..."
                mirror_code=`curl -o /dev/null -m 20 --connect-timeout 20 -sk -w %{http_code} http://soft2.vpser.net`
                if [[ "${mirror_code}" = "200" || "${mirror_code}" = "302" ]]; then
                    echo "Change to mirror http://soft2.vpser.net"
                    Download_Mirror='http://soft2.vpser.net'
                else
                    echo "Try http://soft1.vpser.net ..."
                    mirror_code=`curl -o /dev/null -m 20 --connect-timeout 20 -sk -w %{http_code} http://soft1.vpser.net`
                    if [[ "${mirror_code}" = "200" || "${mirror_code}" = "302" ]]; then
                        echo "Change to mirror http://soft1.vpser.net"
                        Download_Mirror='http://soft1.vpser.net'
                    else
                        echo "Can not connect to download mirror,Please modify lnmp.conf manually."
                        echo "More info,please visit https://lnmp.org/faq/download-url.html"
                        exit 1
                    fi
                fi
            fi
        fi
    fi
}

Color_Text()
{
  echo -e " \e[0;$2m$1\e[0m"
}

Echo_Red()
{
  echo $(Color_Text "$1" "31")
}

Echo_Green()
{
  echo $(Color_Text "$1" "32")
}

Echo_Yellow()
{
  echo $(Color_Text "$1" "33")
}

Echo_Blue()
{
  echo $(Color_Text "$1" "34")
}

Get_PHP_Ext_Dir()
{
    Cur_PHP_Version="`/usr/local/php/bin/php-config --version`"
    zend_ext_dir="`/usr/local/php/bin/php-config --extension-dir`/"
}

Check_Stack()
{
    if [[ -s /usr/local/php/sbin/php-fpm && -s /usr/local/php/etc/php-fpm.conf && -s /etc/init.d/php-fpm && -s /usr/local/nginx/sbin/nginx ]]; then
        Get_Stack="lnmp"
    elif [[ -s /usr/local/nginx/sbin/nginx && -s /usr/local/apache/bin/httpd && -s /usr/local/apache/conf/httpd.conf && -s /etc/init.d/httpd && ! -s /usr/local/php/sbin/php-fpm ]]; then
        Get_Stack="lnmpa"
    elif [[ -s /usr/local/apache/bin/httpd && -s /usr/local/apache/conf/httpd.conf && -s /etc/init.d/httpd && ! -s /usr/local/php/sbin/php-fpm ]]; then
        Get_Stack="lamp"
    else
        Get_Stack="unknow"
    fi
}

Check_DB()
{
    if [[ -s /usr/local/mariadb/bin/mysql && -s /usr/local/mariadb/bin/mysqld_safe && -s /etc/my.cnf ]]; then
        MySQL_Bin="/usr/local/mariadb/bin/mysql"
        MySQL_Config="/usr/local/mariadb/bin/mysql_config"
        MySQL_Dir="/usr/local/mariadb"
        Is_MySQL="n"
        DB_Name="mariadb"
    elif [[ -s /usr/local/mysql/bin/mysql && -s /usr/local/mysql/bin/mysqld_safe && -s /etc/my.cnf ]]; then
        MySQL_Bin="/usr/local/mysql/bin/mysql"
        MySQL_Config="/usr/local/mysql/bin/mysql_config"
        MySQL_Dir="/usr/local/mysql"
        Is_MySQL="y"
        DB_Name="mysql"
    else
        Is_MySQL="None"
        DB_Name="None"
    fi
}

Do_Query()
{
    echo "$1" >/tmp/.mysql.tmp
    Check_DB
    ${MySQL_Bin} --defaults-file=~/.my.cnf </tmp/.mysql.tmp
    return $?
}

Make_TempMycnf()
{
    cat >~/.my.cnf<<EOF
[client]
user=root
password='$1'
EOF
    chmod 600 ~/.my.cnf
}

Verify_DB_Password()
{
    Check_DB
    status=1
    while [ $status -eq 1 ]; do
        read -s -p "Enter current root password of Database (Password will not shown): " DB_Root_Password
        Make_TempMycnf "${DB_Root_Password}"
        Do_Query ""
        status=$?
    done
    echo "OK, MySQL root password correct."
}

TempMycnf_Clean()
{
    if [ -s ~/.my.cnf ]; then
        rm -f ~/.my.cnf
    fi
    if [ -s /tmp/.mysql.tmp ]; then
        rm -f /tmp/.mysql.tmp
    fi
}
