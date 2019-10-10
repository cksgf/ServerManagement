#!/bin/bash

Backup_MySQL()
{
    echo "Starting backup all databases..."
    echo "If the database is large, the backup time will be longer."
    /usr/local/mysql/bin/mysqldump --defaults-file=~/.my.cnf --all-databases > /root/mysql_all_backup${Upgrade_Date}.sql
    if [ $? -eq 0 ]; then
        echo "MySQL databases backup successfully.";
    else
        echo "MySQL databases backup failed,Please backup databases manually!"
        exit 1
    fi
    lnmp stop
    mv /usr/local/mysql /usr/local/oldmysql${Upgrade_Date}
    mv /etc/init.d/mysql /usr/local/oldmysql${Upgrade_Date}/init.d.mysql.bak.${Upgrade_Date}
    mv /etc/my.cnf /usr/local/oldmysql${Upgrade_Date}/my.cnf.bak.${Upgrade_Date}
    if [ "${MySQL_Data_Dir}" != "/usr/local/mysql/var" ]; then
        mv ${MySQL_Data_Dir} ${MySQL_Data_Dir}${Upgrade_Date}
    fi
    if echo "${mysql_version}" | grep -Eqi '^5.5.' &&  echo "${cur_mysql_version}" | grep -Eqi '^5.6.';then
        sed -i 's/STATS_PERSISTENT=0//g' /root/mysql_all_backup${Upgrade_Date}.sql
    fi
}

Upgrade_MySQL51()
{
    Tar_Cd mysql-${mysql_version}.tar.gz mysql-${mysql_version}
    MySQL_Gcc7_Patch
    if [ $InstallInnodb = "y" ]; then
        ./configure --prefix=/usr/local/mysql --with-extra-charsets=complex --enable-thread-safe-client --enable-assembler --with-mysqld-ldflags=-all-static --with-charset=utf8 --enable-thread-safe-client --with-big-tables --with-readline --with-ssl --with-embedded-server --enable-local-infile --with-plugins=innobase ${MySQL51MAOpt}
    else
        ./configure --prefix=/usr/local/mysql --with-extra-charsets=complex --enable-thread-safe-client --enable-assembler --with-mysqld-ldflags=-all-static --with-charset=utf8 --enable-thread-safe-client --with-big-tables --with-readline --with-ssl --with-embedded-server --enable-local-infile ${MySQL51MAOpt}
    fi
    sed -i '/set -ex;/,/done/d' Makefile
    Make_Install
    cd ../

    groupadd mysql
    useradd -s /sbin/nologin -M -g mysql mysql

cat > /etc/my.cnf<<EOF
[client]
#password	= your_password
port		= 3306
socket		= /tmp/mysql.sock

[mysqld]
port		= 3306
socket		= /tmp/mysql.sock
datadir = ${MySQL_Data_Dir}
skip-external-locking
key_buffer_size = 16M
max_allowed_packet = 1M
table_open_cache = 64
sort_buffer_size = 512K
net_buffer_length = 8K
read_buffer_size = 256K
read_rnd_buffer_size = 512K
myisam_sort_buffer_size = 8M
thread_cache_size = 8
query_cache_size = 8M
tmp_table_size = 16M

#skip-networking
max_connections = 500
max_connect_errors = 100
open_files_limit = 65535

log-bin=mysql-bin
binlog_format=mixed
server-id	= 1
expire_logs_days = 10

default_storage_engine = InnoDB
#innodb_data_home_dir = ${MySQL_Data_Dir}
#innodb_data_file_path = ibdata1:10M:autoextend
#innodb_log_group_home_dir = ${MySQL_Data_Dir}
#innodb_buffer_pool_size = 16M
#innodb_additional_mem_pool_size = 2M
#innodb_log_file_size = 5M
#innodb_log_buffer_size = 8M
#innodb_flush_log_at_trx_commit = 1
#innodb_lock_wait_timeout = 50

[mysqldump]
quick
max_allowed_packet = 16M

[mysql]
no-auto-rehash

[myisamchk]
key_buffer_size = 20M
sort_buffer_size = 20M
read_buffer = 2M
write_buffer = 2M

[mysqlhotcopy]
interactive-timeout
EOF
    if [ "${InstallInnodb}" = "y" ]; then
        sed -i 's/^#innodb/innodb/g' /etc/my.cnf
    else
        sed -i '/^default_storage_engine/d' /etc/my.cnf
        sed -i '/skip-external-locking/i\default_storage_engine = MyISAM\nloose-skip-innodb' /etc/my.cnf
    fi
    MySQL_Opt
    if [ -d "${MySQL_Data_Dir}" ]; then
        rm -rf ${MySQL_Data_Dir}/*
    else
        mkdir -p ${MySQL_Data_Dir}
    fi
    chown -R mysql:mysql ${MySQL_Data_Dir}
    /usr/local/mysql/scripts/mysql_install_db --defaults-file=/etc/my.cnf --basedir=/usr/local/mysql --datadir=${MySQL_Data_Dir} --user=mysql

    cat > /etc/ld.so.conf.d/mysql.conf<<EOF
/usr/local/mysql/lib
/usr/local/lib
EOF
    ldconfig
    ln -sf /usr/local/mysql/lib/mysql /usr/lib/mysql
    ln -sf /usr/local/mysql/include/mysql /usr/include/mysql
}

Upgrade_MySQL55()
{
    echo "Starting upgrade MySQL..."

    Tar_Cd mysql-${mysql_version}.tar.gz mysql-${mysql_version}
    MySQL_ARM_Patch
    MySQL_Gcc7_Patch
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql -DSYSCONFDIR=/etc -DWITH_MYISAM_STORAGE_ENGINE=1 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_PARTITION_STORAGE_ENGINE=1 -DWITH_FEDERATED_STORAGE_ENGINE=1 -DEXTRA_CHARSETS=all -DDEFAULT_CHARSET=utf8mb4 -DDEFAULT_COLLATION=utf8mb4_general_ci -DWITH_READLINE=1 -DWITH_EMBEDDED_SERVER=1 -DENABLED_LOCAL_INFILE=1
    Make_Install

    groupadd mysql
    useradd -s /sbin/nologin -M -g mysql mysql

    cat > /etc/my.cnf<<EOF
[client]
#password	= your_password
port		= 3306
socket		= /tmp/mysql.sock

[mysqld]
port		= 3306
socket		= /tmp/mysql.sock
datadir = ${MySQL_Data_Dir}
skip-external-locking
key_buffer_size = 16M
max_allowed_packet = 1M
table_open_cache = 64
sort_buffer_size = 512K
net_buffer_length = 8K
read_buffer_size = 256K
read_rnd_buffer_size = 512K
myisam_sort_buffer_size = 8M
thread_cache_size = 8
query_cache_size = 8M
tmp_table_size = 16M

#skip-networking
max_connections = 500
max_connect_errors = 100
open_files_limit = 65535

log-bin=mysql-bin
binlog_format=mixed
server-id	= 1
expire_logs_days = 10

default_storage_engine = InnoDB
#innodb_data_home_dir = ${MySQL_Data_Dir}
#innodb_data_file_path = ibdata1:10M:autoextend
#innodb_log_group_home_dir = ${MySQL_Data_Dir}
#innodb_buffer_pool_size = 16M
#innodb_additional_mem_pool_size = 2M
#innodb_log_file_size = 5M
#innodb_log_buffer_size = 8M
#innodb_flush_log_at_trx_commit = 1
#innodb_lock_wait_timeout = 50

[mysqldump]
quick
max_allowed_packet = 16M

[mysql]
no-auto-rehash

[myisamchk]
key_buffer_size = 20M
sort_buffer_size = 20M
read_buffer = 2M
write_buffer = 2M

[mysqlhotcopy]
interactive-timeout

${MySQLMAOpt}
EOF
    if [ "${InstallInnodb}" = "y" ]; then
        sed -i 's/^#innodb/innodb/g' /etc/my.cnf
    else
        sed -i '/^default_storage_engine/d' /etc/my.cnf
        sed -i '/skip-external-locking/i\default_storage_engine = MyISAM\nloose-skip-innodb' /etc/my.cnf
    fi
    MySQL_Opt
    if [ -d "${MySQL_Data_Dir}" ]; then
        rm -rf ${MySQL_Data_Dir}/*
    else
        mkdir -p ${MySQL_Data_Dir}
    fi
    chown -R mysql:mysql ${MySQL_Data_Dir}
    /usr/local/mysql/scripts/mysql_install_db --defaults-file=/etc/my.cnf --basedir=/usr/local/mysql --datadir=${MySQL_Data_Dir} --user=mysql

    cat > /etc/ld.so.conf.d/mysql.conf<<EOF
/usr/local/mysql/lib
/usr/local/lib
EOF
    ldconfig
    ln -sf /usr/local/mysql/lib/mysql /usr/lib/mysql
    ln -sf /usr/local/mysql/include/mysql /usr/include/mysql
}

Upgrade_MySQL56()
{
    echo "Starting upgrade MySQL..."
    Tar_Cd mysql-${mysql_version}.tar.gz mysql-${mysql_version}
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql -DSYSCONFDIR=/etc -DWITH_MYISAM_STORAGE_ENGINE=1 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_PARTITION_STORAGE_ENGINE=1 -DWITH_FEDERATED_STORAGE_ENGINE=1 -DEXTRA_CHARSETS=all -DDEFAULT_CHARSET=utf8mb4 -DDEFAULT_COLLATION=utf8mb4_general_ci -DWITH_EMBEDDED_SERVER=1 -DENABLED_LOCAL_INFILE=1
    Make_Install

    groupadd mysql
    useradd -s /sbin/nologin -M -g mysql mysql

cat > /etc/my.cnf<<EOF
[client]
#password   = your_password
port        = 3306
socket      = /tmp/mysql.sock

[mysqld]
port        = 3306
socket      = /tmp/mysql.sock
datadir = ${MySQL_Data_Dir}
skip-external-locking
key_buffer_size = 16M
max_allowed_packet = 1M
table_open_cache = 64
sort_buffer_size = 512K
net_buffer_length = 8K
read_buffer_size = 256K
read_rnd_buffer_size = 512K
myisam_sort_buffer_size = 8M
thread_cache_size = 8
query_cache_size = 8M
tmp_table_size = 16M
performance_schema_max_table_instances = 500

explicit_defaults_for_timestamp = true
#skip-networking
max_connections = 500
max_connect_errors = 100
open_files_limit = 65535

log-bin=mysql-bin
binlog_format=mixed
server-id   = 1
expire_logs_days = 10

#loose-innodb-trx=0
#loose-innodb-locks=0
#loose-innodb-lock-waits=0
#loose-innodb-cmp=0
#loose-innodb-cmp-per-index=0
#loose-innodb-cmp-per-index-reset=0
#loose-innodb-cmp-reset=0
#loose-innodb-cmpmem=0
#loose-innodb-cmpmem-reset=0
#loose-innodb-buffer-page=0
#loose-innodb-buffer-page-lru=0
#loose-innodb-buffer-pool-stats=0
#loose-innodb-metrics=0
#loose-innodb-ft-default-stopword=0
#loose-innodb-ft-inserted=0
#loose-innodb-ft-deleted=0
#loose-innodb-ft-being-deleted=0
#loose-innodb-ft-config=0
#loose-innodb-ft-index-cache=0
#loose-innodb-ft-index-table=0
#loose-innodb-sys-tables=0
#loose-innodb-sys-tablestats=0
#loose-innodb-sys-indexes=0
#loose-innodb-sys-columns=0
#loose-innodb-sys-fields=0
#loose-innodb-sys-foreign=0
#loose-innodb-sys-foreign-cols=0

default_storage_engine = InnoDB
#innodb_data_home_dir = ${MySQL_Data_Dir}
#innodb_data_file_path = ibdata1:10M:autoextend
#innodb_log_group_home_dir = ${MySQL_Data_Dir}
#innodb_buffer_pool_size = 16M
#innodb_log_file_size = 5M
#innodb_log_buffer_size = 8M
#innodb_flush_log_at_trx_commit = 1
#innodb_lock_wait_timeout = 50

[mysqldump]
quick
max_allowed_packet = 16M

[mysql]
no-auto-rehash

[myisamchk]
key_buffer_size = 20M
sort_buffer_size = 20M
read_buffer = 2M
write_buffer = 2M

[mysqlhotcopy]
interactive-timeout

${MySQLMAOpt}
EOF

    if [ "${InstallInnodb}" = "y" ]; then
        sed -i 's/^#innodb/innodb/g' /etc/my.cnf
    else
        sed -i '/^default_storage_engine/d' /etc/my.cnf
        sed -i '/skip-external-locking/i\innodb = OFF\nignore-builtin-innodb\nskip-innodb\ndefault_storage_engine = MyISAM\ndefault_tmp_storage_engine = MyISAM' /etc/my.cnf
        sed -i 's/^#loose-innodb/loose-innodb/g' /etc/my.cnf
    fi
    MySQL_Opt
    if [ -d "${MySQL_Data_Dir}" ]; then
        rm -rf ${MySQL_Data_Dir}/*
    else
        mkdir -p ${MySQL_Data_Dir}
    fi
    chown -R mysql:mysql ${MySQL_Data_Dir}
    /usr/local/mysql/scripts/mysql_install_db --defaults-file=/etc/my.cnf --basedir=/usr/local/mysql --datadir=${MySQL_Data_Dir} --user=mysql

    cat > /etc/ld.so.conf.d/mysql.conf<<EOF
/usr/local/mysql/lib
/usr/local/lib
EOF

    ldconfig
    ln -sf /usr/local/mysql/lib/mysql /usr/lib/mysql
    ln -sf /usr/local/mysql/include/mysql /usr/include/mysql
}

Upgrade_MySQL57()
{
    echo "Starting upgrade MySQL..."
    Tar_Cd mysql-${mysql_version}.tar.gz mysql-${mysql_version}
    Install_Boost
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql -DSYSCONFDIR=/etc -DWITH_MYISAM_STORAGE_ENGINE=1 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_PARTITION_STORAGE_ENGINE=1 -DWITH_FEDERATED_STORAGE_ENGINE=1 -DEXTRA_CHARSETS=all -DDEFAULT_CHARSET=utf8mb4 -DDEFAULT_COLLATION=utf8mb4_general_ci -DWITH_EMBEDDED_SERVER=1 -DENABLED_LOCAL_INFILE=1 ${MySQL_WITH_BOOST}
    Make_Install

    groupadd mysql
    useradd -s /sbin/nologin -M -g mysql mysql

cat > /etc/my.cnf<<EOF
[client]
#password   = your_password
port        = 3306
socket      = /tmp/mysql.sock

[mysqld]
port        = 3306
socket      = /tmp/mysql.sock
datadir = ${MySQL_Data_Dir}
skip-external-locking
key_buffer_size = 16M
max_allowed_packet = 1M
table_open_cache = 64
sort_buffer_size = 512K
net_buffer_length = 8K
read_buffer_size = 256K
read_rnd_buffer_size = 512K
myisam_sort_buffer_size = 8M
thread_cache_size = 8
query_cache_size = 8M
tmp_table_size = 16M
performance_schema_max_table_instances = 500

explicit_defaults_for_timestamp = true
#skip-networking
max_connections = 500
max_connect_errors = 100
open_files_limit = 65535

log-bin=mysql-bin
binlog_format=mixed
server-id   = 1
expire_logs_days = 10
early-plugin-load = ""

default_storage_engine = InnoDB
innodb_data_home_dir = ${MySQL_Data_Dir}
innodb_data_file_path = ibdata1:10M:autoextend
innodb_log_group_home_dir = ${MySQL_Data_Dir}
innodb_buffer_pool_size = 16M
innodb_log_file_size = 5M
innodb_log_buffer_size = 8M
innodb_flush_log_at_trx_commit = 1
innodb_lock_wait_timeout = 50

[mysqldump]
quick
max_allowed_packet = 16M

[mysql]
no-auto-rehash

[myisamchk]
key_buffer_size = 20M
sort_buffer_size = 20M
read_buffer = 2M
write_buffer = 2M

[mysqlhotcopy]
interactive-timeout

${MySQLMAOpt}
EOF

    MySQL_Opt
    if [ -d "${MySQL_Data_Dir}" ]; then
        rm -rf ${MySQL_Data_Dir}/*
    else
        mkdir -p ${MySQL_Data_Dir}
    fi
    chown -R mysql:mysql ${MySQL_Data_Dir}
    /usr/local/mysql/bin/mysqld --initialize-insecure --basedir=/usr/local/mysql --datadir=${MySQL_Data_Dir} --user=mysql

    cat > /etc/ld.so.conf.d/mysql.conf<<EOF
/usr/local/mysql/lib
/usr/local/lib
EOF

    ldconfig
    ln -sf /usr/local/mysql/lib/mysql /usr/lib/mysql
    ln -sf /usr/local/mysql/include/mysql /usr/include/mysql
}

Upgrade_MySQL80()
{
    echo "Starting upgrade MySQL..."
    Tar_Cd mysql-${mysql_version}.tar.gz mysql-${mysql_version}
    Install_Boost
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql -DSYSCONFDIR=/etc -DWITH_MYISAM_STORAGE_ENGINE=1 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_PARTITION_STORAGE_ENGINE=1 -DWITH_FEDERATED_STORAGE_ENGINE=1 -DEXTRA_CHARSETS=all -DDEFAULT_CHARSET=utf8mb4 -DDEFAULT_COLLATION=utf8mb4_general_ci -DWITH_EMBEDDED_SERVER=1 -DENABLED_LOCAL_INFILE=1 ${MySQL_WITH_BOOST}
    Make_Install

    groupadd mysql
    useradd -s /sbin/nologin -M -g mysql mysql

cat > /etc/my.cnf<<EOF
[client]
#password   = your_password
port        = 3306
socket      = /tmp/mysql.sock

[mysqld]
port        = 3306
socket      = /tmp/mysql.sock
datadir = ${MySQL_Data_Dir}
skip-external-locking
key_buffer_size = 16M
max_allowed_packet = 1M
table_open_cache = 64
sort_buffer_size = 512K
net_buffer_length = 8K
read_buffer_size = 256K
read_rnd_buffer_size = 512K
myisam_sort_buffer_size = 8M
thread_cache_size = 8
tmp_table_size = 16M
performance_schema_max_table_instances = 500

explicit_defaults_for_timestamp = true
#skip-networking
max_connections = 500
max_connect_errors = 100
open_files_limit = 65535
default_authentication_plugin = mysql_native_password

log-bin=mysql-bin
binlog_format=mixed
server-id   = 1
binlog_expire_logs_seconds = 864000
early-plugin-load = ""

default_storage_engine = InnoDB
innodb_data_home_dir = ${MySQL_Data_Dir}
innodb_data_file_path = ibdata1:10M:autoextend
innodb_log_group_home_dir = ${MySQL_Data_Dir}
innodb_buffer_pool_size = 16M
innodb_log_file_size = 5M
innodb_log_buffer_size = 8M
innodb_flush_log_at_trx_commit = 1
innodb_lock_wait_timeout = 50

[mysqldump]
quick
max_allowed_packet = 16M

[mysql]
no-auto-rehash

[myisamchk]
key_buffer_size = 20M
sort_buffer_size = 20M
read_buffer = 2M
write_buffer = 2M

[mysqlhotcopy]
interactive-timeout

${MySQLMAOpt}
EOF

    MySQL_Opt
    if [ -d "${MySQL_Data_Dir}" ]; then
        rm -rf ${MySQL_Data_Dir}/*
    else
        mkdir -p ${MySQL_Data_Dir}
    fi
    chown -R mysql:mysql ${MySQL_Data_Dir}
    /usr/local/mysql/bin/mysqld --initialize-insecure --basedir=/usr/local/mysql --datadir=${MySQL_Data_Dir} --user=mysql

    cat > /etc/ld.so.conf.d/mysql.conf<<EOF
/usr/local/mysql/lib
/usr/local/lib
EOF

    ldconfig
    ln -sf /usr/local/mysql/lib/mysql /usr/lib/mysql
    ln -sf /usr/local/mysql/include/mysql /usr/include/mysql
}

Restore_Start_MySQL()
{
    chgrp -R mysql /usr/local/mysql/.
    \cp ${cur_dir}/src/mysql-${mysql_version}/support-files/mysql.server /etc/init.d/mysql
    chmod 755 /etc/init.d/mysql

    ldconfig

    MySQL_Sec_Setting
    /etc/init.d/mysql start

    echo "Restore backup databases..."
    /usr/local/mysql/bin/mysql --defaults-file=~/.my.cnf < /root/mysql_all_backup${Upgrade_Date}.sql
    echo "Repair databases..."
    /usr/local/mysql/bin/mysql_upgrade -u root -p${DB_Root_Password}

    /etc/init.d/mysql stop
    TempMycnf_Clean
    cd ${cur_dir} && rm -rf ${cur_dir}/src/mysql-${mysql_version}

    lnmp start
    if [[ -s /usr/local/mysql/bin/mysql && -s /usr/local/mysql/bin/mysqld_safe && -s /etc/my.cnf ]]; then
        Echo_Green "======== upgrade MySQL completed ======"
    else
        Echo_Red "======== upgrade MySQL failed ======"
        Echo_Red "upgrade MySQL log: /root/upgrade_mysql.log"
        echo "You upload upgrade_mysql.log to LNMP Forum for help."
    fi
}

Upgrade_MySQL()
{
    Check_DB
    if [ "${Is_MySQL}" = "n" ]; then
        Echo_Red "Current database was MariaDB, Can't run MySQL upgrade script."
        exit 1
    fi

    Verify_DB_Password

    cur_mysql_version=`/usr/local/mysql/bin/mysql_config --version`
    mysql_version=""
    echo "Current MYSQL Version:${cur_mysql_version}"
    echo "You can get version number from http://dev.mysql.com/downloads/mysql/"
    Echo_Yellow "Please input MySQL Version you want."
    read -p "(example: 5.5.60 ): " mysql_version
    if [ "${mysql_version}" = "" ]; then
        echo "Error: You must input MySQL Version!!"
        exit 1
    fi

    if [ "${mysql_version}" == "${cur_mysql_version}" ]; then
        echo "Error: The upgrade MYSQL Version is the same as the old Version!!"
        exit 1
    fi

    #do you want to install the InnoDB Storage Engine?
    echo "==========================="

    InstallInnodb="y"
    Echo_Yellow "Do you want to install the InnoDB Storage Engine?"
    read -p "(Default yes,if you want please enter: y , if not please enter: n): " InstallInnodb

    case "${InstallInnodb}" in
    [yY][eE][sS]|[yY])
        echo "You will install the InnoDB Storage Engine"
        InstallInnodb="y"
        ;;
    [nN][oO]|[nN])
        echo "You will NOT install the InnoDB Storage Engine!"
        InstallInnodb="n"
        ;;
    *)
        echo "No input, The InnoDB Storage Engine will enable."
        InstallInnodb="y"
        ;;
    esac

    mysql_short_version=`echo ${mysql_version} | cut -d. -f1-2`

    echo "=================================================="
    echo "You will upgrade MySQL Version to ${mysql_version}"
    echo "=================================================="

    if [ -s /usr/local/include/jemalloc/jemalloc.h ] && lsof -n|grep "libjemalloc.so"|grep -q "mysqld"; then
        MySQL51MAOpt='--with-mysqld-ldflags=-ljemalloc'
        MySQL55MAOpt="-DCMAKE_EXE_LINKER_FLAGS='-ljemalloc' -DWITH_SAFEMALLOC=OFF"
    elif [ -s /usr/local/include/gperftools/tcmalloc.h ] && lsof -n|grep "libtcmalloc.so"|grep -q "mysqld"; then
        MySQL51MAOpt='--with-mysqld-ldflags=-ltcmalloc'
        MySQL55MAOpt="-DCMAKE_EXE_LINKER_FLAGS='-ltcmalloc' -DWITH_SAFEMALLOC=OFF"
    else
        MySQL51MAOpt=''
        MySQL55MAOpt=''
    fi

    Press_Start

    echo "============================check files=================================="
    cd ${cur_dir}/src
    if [ -s mysql-${mysql_version}.tar.gz ]; then
        echo "mysql-${mysql_version}.tar.gz [found]"
    else
        echo "Notice: mysql-${mysql_version}.tar.gz not found!!!download now......"
        country=`curl -sSk --connect-timeout 10 -m 60 https://ip.vpser.net/country`
        if [ "${country}" = "CN" ]; then
            wget -c --progress=bar:force http://mirrors.ustc.edu.cn/mysql-ftp/Downloads/MySQL-${mysql_short_version}/mysql-${mysql_version}.tar.gz
            if [ $? -ne 0 ]; then
                wget -c --progress=bar:force http://cdn.mysql.com/Downloads/MySQL-${mysql_short_version}/mysql-${mysql_version}.tar.gz
            fi
        else
            wget -c --progress=bar:force http://cdn.mysql.com/Downloads/MySQL-${mysql_short_version}/mysql-${mysql_version}.tar.gz
        fi
        if [ $? -eq 0 ]; then
            echo "Download mysql-${mysql_version}.tar.gz successfully!"
        else
            echo "You enter MySQL Version was:"${mysql_version}
            Echo_Red "Error! You entered a wrong version number, please check!"
            sleep 5
            exit 1
        fi
    fi
    echo "============================check files=================================="

    Backup_MySQL
    if [ "${mysql_short_version}" = "5.1" ]; then
        Upgrade_MySQL51
    elif [ "${mysql_short_version}" = "5.5" ]; then
        Upgrade_MySQL55
    elif [ "${mysql_short_version}" = "5.6" ]; then
        Upgrade_MySQL56
    elif [ "${mysql_short_version}" = "5.7" ]; then
        Upgrade_MySQL57
    elif [ "${mysql_short_version}" = "8.0" ]; then
        Upgrade_MySQL80
    fi
    Restore_Start_MySQL
}
