#!/bin/bash
# 获取所有的bucket桶
# 将bucket名称与备份路径进行统一
# 同步所有bucket
# 设置定时任务
all_bucket=`s3cmd ls|awk '{print $3}'`
for i in $all_bucket
do
bucket_name=`echo $i|awk -F '//' '{print $2}'`
echo 'start $bucket_name sync'
s3cmd sync --skip-exist $i/ -p /ossData/$bucket_name/
echo '$bucket_name sync sucess!'
done

