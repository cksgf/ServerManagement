#!/bin/bash

MariaDB_WITHSSL()
{
    if /usr/bin/openssl version | grep -Eqi "OpenSSL 1.1.*"; then
        if [[ "${DBSelect}" =~ ^[78]$ ]] || echo "${mysql_version}" | grep -Eqi '^10.[01].'; then
            Install_Openssl
            MariaDBWITHSSL='-DWITH_SSL=/usr/local/openssl'
        else
            MariaDBWITHSSL=''
        fi
    fi
}

Mariadb_Sec_Setting()
{
    cat > /etc/ld.so.conf.d/mariadb.conf<<EOF
    /usr/local/mariadb/lib
    /usr/local/lib
EOF
    ldconfig

    if [ -d "/proc/vz" ];then
        ulimit -s unlimited
    fi
    
    if [ -s /bin/systemctl ]; then
        systemctl enable mariadb.service
    fi
    StartUp mariadb
    /etc/init.d/mariadb start

    ln -sf /usr/local/mariadb/bin/mysql /usr/bin/mysql
    ln -sf /usr/local/mariadb/bin/mysqldump /usr/bin/mysqldump
    ln -sf /usr/local/mariadb/bin/myisamchk /usr/bin/myisamchk
    ln -sf /usr/local/mariadb/bin/mysqld_safe /usr/bin/mysqld_safe
    ln -sf /usr/local/mariadb/bin/mysqlcheck /usr/bin/mysqlcheck

    /etc/init.d/mariadb restart
    sleep 2

    /usr/local/mariadb/bin/mysqladmin -u root password "${DB_Root_Password}"
    if [ $? -ne 0 ]; then
        echo "failed, try other way..."
        /etc/init.d/mariadb restart
        cat >~/.emptymy.cnf<<EOF
[client]
user=root
password=''
EOF
        /usr/local/mariadb/bin/mysql --defaults-file=~/.emptymy.cnf -e "UPDATE mysql.user SET Password=PASSWORD('${DB_Root_Password}') WHERE User='root';"
        [ $? -eq 0 ] && echo "Set password Sucessfully." || echo "Set password failed!"
        /usr/local/mariadb/bin/mysql --defaults-file=~/.emptymy.cnf -e "FLUSH PRIVILEGES;"
        [ $? -eq 0 ] && echo "FLUSH PRIVILEGES Sucessfully." || echo "FLUSH PRIVILEGES failed!"
        rm -f ~/.emptymy.cnf
    fi
    /etc/init.d/mariadb restart

    Make_TempMycnf "${DB_Root_Password}"
    Do_Query ""
    if [ $? -eq 0 ]; then
        echo "OK, MySQL root password correct."
    fi
    echo "Update root password..."
    Do_Query "UPDATE mysql.user SET Password=PASSWORD('${DB_Root_Password}') WHERE User='root';"
    [ $? -eq 0 ] && echo " ... Success." || echo " ... Failed!"
    echo "Remove anonymous users..."
    Do_Query "DELETE FROM mysql.user WHERE User='';"
    Do_Query "DROP USER ''@'%';"
    [ $? -eq 0 ] && echo " ... Success." || echo " ... Failed!"
    echo "Disallow root login remotely..."
    Do_Query "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
    [ $? -eq 0 ] && echo " ... Success." || echo " ... Failed!"
    echo "Remove test database..."
    Do_Query "DROP DATABASE test;"
    [ $? -eq 0 ] && echo " ... Success." || echo " ... Failed!"
    echo "Reload privilege tables..."
    Do_Query "FLUSH PRIVILEGES;"
    [ $? -eq 0 ] && echo " ... Success." || echo " ... Failed!"

    /etc/init.d/mariadb restart
    /etc/init.d/mariadb stop
}

Check_MariaDB_Data_Dir()
{
    if [ -d "${MariaDB_Data_Dir}" ]; then
        datetime=$(date +"%Y%m%d%H%M%S")
        mkdir /root/mariadb-data-dir-backup${datetime}/
        \cp ${MariaDB_Data_Dir}/* /root/mariadb-data-dir-backup${datetime}/
        rm -rf ${MariaDB_Data_Dir}/*
    else
        mkdir -p ${MariaDB_Data_Dir}
    fi
}

Install_MariaDB_5()
{
    Echo_Blue "[+] Installing ${Mariadb_Ver}..."
    rm -f /etc/my.cnf
    Tar_Cd ${Mariadb_Ver}.tar.gz ${Mariadb_Ver}
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mariadb -DWITH_ARIA_STORAGE_ENGINE=1 -DWITH_XTRADB_STORAGE_ENGINE=1 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_PARTITION_STORAGE_ENGINE=1 -DWITH_MYISAM_STORAGE_ENGINE=1 -DWITH_FEDERATED_STORAGE_ENGINE=1 -DEXTRA_CHARSETS=all -DDEFAULT_CHARSET=utf8mb4 -DDEFAULT_COLLATION=utf8mb4_general_ci -DWITH_READLINE=1 -DWITH_EMBEDDED_SERVER=1 -DENABLED_LOCAL_INFILE=1
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
        sed -i 's/^#loose-innodb/loose-innodb/g' /etc/my.cnf
        sed -i '/skip-external-locking/i\default_storage_engine = MyISAM\nloose-skip-innodb' /etc/my.cnf
    fi
    MySQL_Opt
    Check_MariaDB_Data_Dir
    chown -R mariadb:mariadb ${MariaDB_Data_Dir}
    /usr/local/mariadb/scripts/mysql_install_db --defaults-file=/etc/my.cnf --basedir=/usr/local/mariadb --datadir=${MariaDB_Data_Dir} --user=mariadb
    chgrp -R mariadb /usr/local/mariadb/.
    \cp support-files/mysql.server /etc/init.d/mariadb
    chmod 755 /etc/init.d/mariadb

    Mariadb_Sec_Setting
}

Install_MariaDB_10()
{
    Echo_Blue "[+] Installing ${Mariadb_Ver}..."
    rm -f /etc/my.cnf
    MariaDB_WITHSSL
    Tar_Cd ${Mariadb_Ver}.tar.gz ${Mariadb_Ver}
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mariadb -DWITH_ARIA_STORAGE_ENGINE=1 -DWITH_XTRADB_STORAGE_ENGINE=1 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_PARTITION_STORAGE_ENGINE=1 -DWITH_MYISAM_STORAGE_ENGINE=1 -DWITH_FEDERATED_STORAGE_ENGINE=1 -DEXTRA_CHARSETS=all -DDEFAULT_CHARSET=utf8mb4 -DDEFAULT_COLLATION=utf8mb4_general_ci -DWITH_READLINE=1 -DWITH_EMBEDDED_SERVER=1 -DENABLED_LOCAL_INFILE=1 ${MariaDBWITHSSL}
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

explicit_defaults_for_timestamp = true
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
        sed -i 's/^#loose-innodb/loose-innodb/g' /etc/my.cnf
        sed -i '/skip-external-locking/i\default_storage_engine = MyISAM\nloose-skip-innodb' /etc/my.cnf
    fi
    MySQL_Opt
    Check_MariaDB_Data_Dir
    chown -R mariadb:mariadb ${MariaDB_Data_Dir}
    /usr/local/mariadb/scripts/mysql_install_db --defaults-file=/etc/my.cnf --basedir=/usr/local/mariadb --datadir=${MariaDB_Data_Dir} --user=mariadb
    chgrp -R mariadb /usr/local/mariadb/.
    \cp support-files/mysql.server /etc/init.d/mariadb
    chmod 755 /etc/init.d/mariadb

    Mariadb_Sec_Setting
}

Install_MariaDB_101()
{
    Echo_Blue "[+] Installing ${Mariadb_Ver}..."
    rm -f /etc/my.cnf
    MariaDB_WITHSSL
    Tar_Cd ${Mariadb_Ver}.tar.gz ${Mariadb_Ver}
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mariadb -DWITH_ARIA_STORAGE_ENGINE=1 -DWITH_XTRADB_STORAGE_ENGINE=1 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_PARTITION_STORAGE_ENGINE=1 -DWITH_MYISAM_STORAGE_ENGINE=1 -DWITH_FEDERATED_STORAGE_ENGINE=1 -DEXTRA_CHARSETS=all -DDEFAULT_CHARSET=utf8mb4 -DDEFAULT_COLLATION=utf8mb4_general_ci -DWITH_READLINE=1 -DWITH_EMBEDDED_SERVER=1 -DENABLED_LOCAL_INFILE=1 -DWITHOUT_TOKUDB=1 ${MariaDBWITHSSL}
    Make_Install

    groupadd mariadb
    useradd -s /sbin/nologin -M -g mariadb mariadb

cat > /etc/my.cnf<<EOF
[client]
#password   = your_password
port        = 3306
socket      = /tmp/mysql.sock

[mysqld]
port        = 3306
socket      = /tmp/mysql.sock
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

explicit_defaults_for_timestamp = true
#skip-networking
max_connections = 500
max_connect_errors = 100
open_files_limit = 65535

log-bin=mysql-bin
binlog_format=mixed
server-id   = 1
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
        sed -i 's/^#loose-innodb/loose-innodb/g' /etc/my.cnf
        sed -i '/skip-external-locking/i\default_storage_engine = MyISAM\nloose-skip-innodb' /etc/my.cnf
    fi
    MySQL_Opt
    Check_MariaDB_Data_Dir
    chown -R mariadb:mariadb ${MariaDB_Data_Dir}
    /usr/local/mariadb/scripts/mysql_install_db --defaults-file=/etc/my.cnf --basedir=/usr/local/mariadb --datadir=${MariaDB_Data_Dir} --user=mariadb
    chgrp -R mariadb /usr/local/mariadb/.
    \cp support-files/mysql.server /etc/init.d/mariadb
    chmod 755 /etc/init.d/mariadb

    Mariadb_Sec_Setting
}

Install_MariaDB_102()
{
    Echo_Blue "[+] Installing ${Mariadb_Ver}..."
    rm -f /etc/my.cnf
    Tar_Cd ${Mariadb_Ver}.tar.gz ${Mariadb_Ver}
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mariadb -DWITH_ARIA_STORAGE_ENGINE=1 -DWITH_XTRADB_STORAGE_ENGINE=1 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_PARTITION_STORAGE_ENGINE=1 -DWITH_MYISAM_STORAGE_ENGINE=1 -DWITH_FEDERATED_STORAGE_ENGINE=1 -DEXTRA_CHARSETS=all -DDEFAULT_CHARSET=utf8mb4 -DDEFAULT_COLLATION=utf8mb4_general_ci -DWITH_READLINE=1 -DWITH_EMBEDDED_SERVER=1 -DENABLED_LOCAL_INFILE=1 -DWITHOUT_TOKUDB=1
    Make_Install

    groupadd mariadb
    useradd -s /sbin/nologin -M -g mariadb mariadb

cat > /etc/my.cnf<<EOF
[client]
#password   = your_password
port        = 3306
socket      = /tmp/mysql.sock

[mysqld]
port        = 3306
socket      = /tmp/mysql.sock
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

explicit_defaults_for_timestamp = true
#skip-networking
max_connections = 500
max_connect_errors = 100
open_files_limit = 65535

log-bin=mysql-bin
binlog_format=mixed
server-id   = 1
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
        sed -i 's/^#loose-innodb/loose-innodb/g' /etc/my.cnf
        sed -i '/skip-external-locking/i\default_storage_engine = MyISAM\nloose-skip-innodb' /etc/my.cnf
    fi
    MySQL_Opt
    Check_MariaDB_Data_Dir
    chown -R mariadb:mariadb ${MariaDB_Data_Dir}
    /usr/local/mariadb/scripts/mysql_install_db --defaults-file=/etc/my.cnf --basedir=/usr/local/mariadb --datadir=${MariaDB_Data_Dir} --user=mariadb
    chgrp -R mariadb /usr/local/mariadb/.
    \cp support-files/mysql.server /etc/init.d/mariadb
    chmod 755 /etc/init.d/mariadb

    Mariadb_Sec_Setting
}

Install_MariaDB_103()
{
    Echo_Blue "[+] Installing ${Mariadb_Ver}..."
    rm -f /etc/my.cnf
    Tar_Cd ${Mariadb_Ver}.tar.gz ${Mariadb_Ver}
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mariadb -DWITH_ARIA_STORAGE_ENGINE=1 -DWITH_XTRADB_STORAGE_ENGINE=1 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_PARTITION_STORAGE_ENGINE=1 -DWITH_MYISAM_STORAGE_ENGINE=1 -DWITH_FEDERATED_STORAGE_ENGINE=1 -DEXTRA_CHARSETS=all -DDEFAULT_CHARSET=utf8mb4 -DDEFAULT_COLLATION=utf8mb4_general_ci -DWITH_READLINE=1 -DWITH_EMBEDDED_SERVER=1 -DENABLED_LOCAL_INFILE=1 -DWITHOUT_TOKUDB=1
    Make_Install

    groupadd mariadb
    useradd -s /sbin/nologin -M -g mariadb mariadb

cat > /etc/my.cnf<<EOF
[client]
#password   = your_password
port        = 3306
socket      = /tmp/mysql.sock

[mysqld]
port        = 3306
socket      = /tmp/mysql.sock
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

explicit_defaults_for_timestamp = true
#skip-networking
max_connections = 500
max_connect_errors = 100
open_files_limit = 65535

log-bin=mysql-bin
binlog_format=mixed
server-id   = 1
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
        sed -i 's/^#loose-innodb/loose-innodb/g' /etc/my.cnf
        sed -i '/skip-external-locking/i\default_storage_engine = MyISAM\nloose-skip-innodb' /etc/my.cnf
    fi
    MySQL_Opt
    Check_MariaDB_Data_Dir
    chown -R mariadb:mariadb ${MariaDB_Data_Dir}
    /usr/local/mariadb/scripts/mysql_install_db --defaults-file=/etc/my.cnf --basedir=/usr/local/mariadb --datadir=${MariaDB_Data_Dir} --user=mariadb
    chgrp -R mariadb /usr/local/mariadb/.
    \cp support-files/mysql.server /etc/init.d/mariadb
    chmod 755 /etc/init.d/mariadb

    Mariadb_Sec_Setting
}
