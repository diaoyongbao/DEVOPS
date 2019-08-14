#/bin/sh
tar zxvf jdk-8u191-linux-x64.tar.gz -C /usr/local/
ln -s jdk1.8 java
sed -i '$aexport JAVA_HOME=/usr/local/java \nexport PATH=$JAVA_HOME/bin:$PATH\nexport CLASSPATH=$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar' /etc/profile
source /etc/profile
java -version

