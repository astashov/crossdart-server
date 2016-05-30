#!/bin/bash
export PATH=/usr/local/bin:/usr/bin:/bin/:/usr/lib/dart/bin
export HOME=/root
DIRROOT=/crossdart-server

case $1 in
   start)
      echo $$ > /var/run/crossdart_server_generator.pid;
      mkdir -p $DIRROOT/logs
      exec 2>&1 dart $DIRROOT/bin/generator.dart --dirroot $DIRROOT 1>>$DIRROOT/logs/log_generator.txt
      ;;
    stop)
      kill `cat /var/run/crossdart_server_generator.pid` ;;
    *)
      echo "usage: monit_generator.sh {start|stop}" ;;
esac
exit 0