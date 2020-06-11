#/bin/bash
#all 全量备份
#increment 增量备份
#upload2s3 上传对象存储
#定时任务写法,全量每周日01：00备份一次，增量周一-周六每天01：00备份
#0 1 * * 7 
#0 1 * * 1-6 

case "$1" in
all)
#删除上次全量备份的内容
    rm -rf /data/mysql_backup/all/*
    innobackupex --user=root --password=Jwt@1234 /data/mysql_backup/all
    s3cmd put -r /data/mysql_backup/all/ s3://backup/mysql/172.18.63.141/all/ 
    echo "backup complete!!"
    ;;
increment)
    #获取全备的文件夹
    dirSrc=$(ls /data/mysql_backup/all -l | awk '/^d/{print $NF}')
    innobackupex --user=root --password=Jwt@1234    --incremental --incremental-basedir /data/mysql_backup/all/$dirSrc /data/mysql_backup/increment/
    s3cmd put -r /data/mysql_backup/increment/ s3://backup/mysql/172.18.63.141/increment/
    echo "backup complete!!"
    ;;
*)
 echo "Usage: $0 {all|increment}"
 exit 1
esac
 
exit 0

