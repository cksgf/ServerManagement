#!/bin/bash

Backup_MariaDB()
{
    echo "Starting backup all databases..."
    echo "If the database is large, the backup time will be longer."
    /usr/local/mariadb/bin/mysqldump --defaults-file=~/.my.cnf --all-databases > /root/mariadb_all_backup${Upgrade_Date}.sql
    if [ $? -eq 0 ]; then
        echo "MariaDB databases backup successfully.";
    else
        echo "MariaDB databases backup failed,Please backup databases manually!"
        exit 1
    fi
    lnmp stop

    mv /usr/local/mariadb /usr/local/oldmariadb${Upgrade_Date}
    mv /etc/init.d/mariadb /usr/local/oldmariadb${Upgrade_Date}/init.d.mariadb.bak.${Upgrade_Date}
    mv /etc/my.cnf /usr/local/oldmariadb${Upgrade_Date}/my.cnf.mariadb.bak.${Upgrade_Date}
    if [ "${MariaDB_Data_Dir}" != "/usr/local/mariadb/var" ]; then
        mv ${MariaDB_Data_Dir} ${MariaDB_Data_Dir}${Upgrade_Date}
    fi
    if echo "${mariadb_version}" | grep -Eqi '^5.5.' &&  echo "${cur_mariadb_version}" | grep -Eqi '^10.';then
        sed -i 's/STATS_PERSISTENT=0//g' /root/mariadb_all_backup${Upgrade_Date}.sql
    fi
}

Upgrade_MariaDB()
{
    Check_DB
    if [ "${Is_MySQL}" = "y" ]; then
        Echo_Red "Current database was MySQL, Can't run MariaDB upgrade script."
        exit 1
    fi

    Verify_DB_Password

    cur_mariadb_version=`/usr/local/mariadb/bin/mysql_config --version`
    mariadb_version=""
    echo "Current MariaDB Version:${cur_mariadb_version}"
    echo "You can get version number from https://downloads.mariadb.org/"
    Echo_Yellow "Please enter MariaDB Version you want."
    read -p "(example: 10.0.35 ): " mariadb_version
    if [ "${mariadb_version}" = "" ]; then
        echo "Error: You must input MariaDB Version!!"
        exit 1
    fi

    #do you want to install the InnoDB Storage Engine?
    echo "==========================="

    InstallInnodb="y"
    Echo_Yellow "Do you want to install the InnoDB Storage Engine?"
    read -p "(Default yes, if you want please enter: y , if not please enter: n): " InstallInnodb

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
    esac

    echo "====================================================================="
    echo "You will upgrade MariaDB V${cur_mariadb_version} to V${mariadb_version}"
    echo "====================================================================="

    if [ -s /usr/local/include/jemalloc/jemalloc.h ] && lsof -n|grep "libjemalloc.so"|grep -q "mysqld"; then
        MariaDBMAOpt=''
    elif [ -s /usr/local/include/gperftools/tcmalloc.h ] && lsof -n|grep "libtcmalloc.so"|grep -q "mysqld"; then
        MariaDBMAOpt="-DCMAKE_EXE_LINKER_FLAGS='-ltcmalloc' -DWITH_SAFEMALLOC=OFF"
    else
        MariaDBMAOpt=''
    fi

    Press_Start

    echo "============================check files=================================="
    cd ${cur_dir}/src
    if [ -s mariadb-${mariadb_version}.tar.gz ]; then
        echo "mariadb-${mariadb_version}.tar.gz [found]"
    else
        echo "Notice: mariadb-${mariadb_version}.tar.gz not found!!!download now......"
        wget -c --progress=bar:force https://downloads.mariadb.org/interstitial/mariadb-${mariadb_version}/source/mariadb-${mariadb_version}.tar.gz
        if [ $? -eq 0 ]; then
            echo "Download mariadb-${mariadb_version}.tar.gz successfully!"
        else
            wget -c --progress=bar:force https://downloads.mariadb.org/interstitial/mariadb-${mariadb_version}/kvm-tarbake-jaunty-x86/mariadb-${mariadb_version}.tar.gz
            if [ $? -eq 0 ]; then
                echo "Download mariadb-${mariadb_version}.tar.gz successfully!"
            else
                echo "You enter MariaDB Version was:"${mariadb_version}
                Echo_Red "Error! You entered a wrong version number, please check!"
                sleep 5
                exit 1
            fi
        fi
    fi
    echo "============================check files=================================="

    Backup_MariaDB

    echo "Starting upgrade MariaDB..."
    Tar_Cd mariadb-${mariadb_version}.tar.gz mariadb-${mariadb_version}
    MariaDB_WITHSSL
    if echo "${mariadb_version}" | grep -Eqi '^10.[123].';then
        cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mariadb -DWITH_ARIA_STORAGE_ENGINE=1 -DWITH_XTRADB_STORAGE_ENGINE=1 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_PARTITION_STORAGE_ENGINE=1 -DWITH_MYISAM_STORAGE_ENGINE=1 -DWITH_FEDERATED_STORAGE_ENGINE=1 -DEXTRA_CHARSETS=all -DDEFAULT_CHARSET=utf8mb4 -DDEFAULT_COLLATION=utf8mb4_general_ci -DWITH_READLINE=1 -DWITH_EMBEDDED_SERVER=1 -DENABLED_LOCAL_INFILE=1 -DWITHOUT_TOKUDB=1 ${MariaDBWITHSSL}
    else
        cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mariadb -DWITH_ARIA_STORAGE_ENGINE=1 -DWITH_XTRADB_STORAGE_ENGINE=1 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_PARTITION_STORAGE_ENGINE=1 -DWITH_MYISAM_STORAGE_ENGINE=1 -DWITH_FEDERATED_STORAGE_ENGINE=1 -DEXTRA_CHARSETS=all -DDEFAULT_CHARSET=utf8mb4 -DDEFAULT_COLLATION=utf8mb4_general_ci -DWITH_READLINE=1 -DWITH_EMBEDDED_SERVER=1 -DENABLED_LOCAL_INFILE=1 ${MariaDBWITHSSL}
    fi
    Make_Install

    groupadd mariadb
    useradd -s /sbin/nologin -M -g mariadb mariadb

cat > /etc/my.cnf<<EOF
[client]
#password	= your_password
port		= 3306
socket		= /tmp/mysql.sock

[mysqld]
port		= 3306
socket		= /tmp/mysql.sock
user    = mariadb
basedir = /usr/local/mariadb
datadir = ${MariaDB_Data_Dir}
log_error = ${MariaDB_Data_Dir}/mariadb.err
pid-file = ${MariaDB_Data_Dir}/mariadb.pid
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
#innodb_file_per_table = 1
#innodb_data_home_dir = ${MariaDB_Data_Dir}
#innodb_data_file_path = ibdata1:10M:autoextend
#innodb_log_group_home_dir = ${MariaDB_Data_Dir}
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
        sed -i '/skip-external-locking/i\default_storage_engine = MyISAM\nloose-skip-innodb' /etc/my.cnf
    fi
    MySQL_Opt
    if [ -d "${MariaDB_Data_Dir}" ]; then
        rm -rf ${MariaDB_Data_Dir}/*
    else
        mkdir -p ${MariaDB_Data_Dir}
    fi
    chown -R mariadb:mariadb ${MariaDB_Data_Dir}
    /usr/local/mariadb/scripts/mysql_install_db --defaults-file=/etc/my.cnf --basedir=/usr/local/mariadb --datadir=${MariaDB_Data_Dir} --user=mariadb
    chgrp -R mariadb /usr/local/mariadb/.
    \cp support-files/mysql.server /etc/init.d/mariadb
    chmod 755 /etc/init.d/mariadb

    Mariadb_Sec_Setting
    /etc/init.d/mariadb start

    echo "Restore backup databases..."
    /usr/local/mariadb/bin/mysql --defaults-file=~/.my.cnf < /root/mariadb_all_backup${Upgrade_Date}.sql
    echo "Repair databases..."
    /usr/local/mariadb/bin/mysql_upgrade -u root -p${DB_Root_Password}

    /etc/init.d/mariadb stop
    TempMycnf_Clean
    cd ${cur_dir} && rm -rf ${cur_dir}/src/mariadb-${mariadb_version}

    lnmp start
    if [[ -s /usr/local/mariadb/bin/mysql && -s /usr/local/mariadb/bin/mysqld_safe && -s /etc/my.cnf ]]; then
        Echo_Green "======== upgrade MariaDB completed ======"
    else
        Echo_Red "======== upgrade MariaDB failed ======"
        Echo_Red "upgrade MariaDB log: /root/upgrade_mariadb.log"
        echo "You upload upgrade_mariadb.log to LNMP Forum for help."
    fi
}
