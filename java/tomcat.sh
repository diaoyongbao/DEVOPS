#!/bin/bash
#description:tomcat7 start stop restart
#processname:tomcat7
#chkconfig:234 20 80
CATALINA_HOME=/usr/local/tomcat
case $1 in 
	start)
		sh $CATALINA_HOME/bin/startup.sh
		;;
	stop)
		sh $CATALINA_HOME/bin/shutdown.sh
		;;
	restart)
		sh $CATALINA_HOME/bin/shutdown.sh
		sh $CATALINA_HOME/bin/startup.sh
		;;
	*)
		ehco "please use : tomcat {start | stop | restart}"
		;;
esac
exit 0