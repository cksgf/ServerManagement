#!/bin/bash
#function:cut nginx log files for lnmp v0.5 and v0.6
#author: https://lnmp.org

#set the path to nginx log files
log_files_path="/home/wwwlogs/"
log_files_dir=${log_files_path}$(date -d "yesterday" +"%Y")/$(date -d "yesterday" +"%m")
#set nginx log files you want to cut
log_files_name=(access vpser licess)
#set the path to nginx.
nginx_sbin="/usr/local/nginx/sbin/nginx"
#Set how long you want to save
save_days=30

############################################
#Please do not modify the following script #
############################################
mkdir -p $log_files_dir

log_files_num=${#log_files_name[@]}

#cut nginx log files
for((i=0;i<$log_files_num;i++));do
mv ${log_files_path}${log_files_name[i]}.log ${log_files_dir}/${log_files_name[i]}_$(date -d "yesterday" +"%Y%m%d").log
done

#delete 30 days ago nginx log files
find $log_files_path -mtime +$save_days -exec rm -rf {} \; 

$nginx_sbin -s reload