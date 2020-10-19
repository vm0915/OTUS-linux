#!/bin/bash

LOGFILE=/vagrant/access-4560-644067.log
VAR1=`wc -l < $LOGFILE`

while [ "$VAR1" -ge "0" ]
do
  cat $LOGFILE | tail -n $VAR1 | head -n 50 >> /vagrant/growing.log
  VAR1=$(($VAR1-50))
  sleep 50
done
