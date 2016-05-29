#!/bin/bash

export PATH=/usr/local/bin:/usr/bin:/bin/:/usr/lib/dart/bin
export HOME=/root
DIRROOT=/crossdart-server

case $1 in
   start)
      echo $$ > /var/run/crossdart_server.pid;
      mkdir -p $DIRROOT/logs
      exec 2>&1 dart $DIRROOT/bin/main.dart 1>>$DIRROOT/logs/log.txt
      ;;
    stop)
      kill `cat /var/run/crossdart_server.pid` ;;
    *)
      echo "usage: monit.sh {start|stop}" ;;
esac
exit 0