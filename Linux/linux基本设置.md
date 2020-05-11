## 时间同步服务
需要注意的是 查看是否有ntpdate服务
crontab -e
MAILTO=""   #此设置不会出现邮件提醒
*/5 * * * * /usr/sbin/ntpdate pool.ntp.org