#!/bin/bash
# description: tomcat 的初始化脚本

tar -zxf apache-tomcat-8.5.39.tar.gz -C /usr/local/
ln -s /usr/local/apache-tomcat-8.5.39/  /usr/local/tomcat
cp tomcat.sh /etc/init.d/tomcat
chmod u+x /etc/init.d/tomcat
chkconfig --add tomcat
chkconfig tomcat on
sed -i '23a export JAVA_HOME=/usr/local/java\
export JRE_HOME=${JAVA_HOME}/jre' /usr/local/tomcat/bin/setclasspath.sh
service tomcat start
sleep 10s
curl http://localhost:8080
