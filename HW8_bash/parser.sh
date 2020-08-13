#!/bin/bash

# передача параметра X и Y при запуске скрипта
X=$1
Y=$2

# объявление переменных
LOGFILE=/vagrant/growing.log
PARTLOG=/vagrant/part.log
LOCKFILE=/run/parser.pid
DIR=/var/lib/parser
TIMESTAMP=/var/lib/parser/last.timestamp
MAILTEXT=/var/lib/parser/mail.text

if [ ! -d "$DIR" ]
  then 
  mkdir $DIR
fi

# проверка что процесс уже не идет
if (set -o noclobber; echo "$$" > $LOCKFILE) 2> /dev/null
then
# trap на случай преждевременного завершения
trap 'rm -f "$LOCKFILE"; exit $?' INT TERM EXIT

# узнать на каком времени закончился прошлый анализ лога
LASTTIMESTAMP=$(cat $TIMESTAMP 2> /dev/null)

if [ ! -z "$LASTTIMESTAMP" ]
  then
  # найти строчку с этим временем в файле и скопировать записи с этого момента в отдельный файл
  LINE=$(grep --line-number -F "$LASTTIMESTAMP" $LOGFILE | cut --fields 1 --delimiter ":")
else
  LINE=0
fi

COUNT=$(cat $LOGFILE | wc -l )
cat $LOGFILE | tail -n $(($COUNT-$LINE)) > $PARTLOG

# определить последнюю временную метку в этом срезе
NEWTIMESTAMP=$(cat $PARTLOG | tail -1 | cut --fields 1 --delimiter "]" | cut --fields 2 --delimiter "[")

# добавить в письмо сведения о времени
echo Time range: $LASTTIMESTAMP --- $NEWTIMESTAMP > $MAILTEXT

# вывод Х ip-адресов с наибольшим количеством запросов
echo "ip адреса с наибольшим количеством запросов:" >> $MAILTEXT
cat $PARTLOG | cut --fields 1 --delimiter " " | sort | uniq -c | sort -k1 -n -r | head -$X >> $MAILTEXT

# вывод Y наиболее запрашиваемых URL
echo "наиболее запрашиваемые URL:" >> $MAILTEXT
cat $PARTLOG | cut --fields 1 --delimiter " " | sort | uniq -c| sort -k1 -n -r | head -$Y >> $MAILTEXT

# вывод ошибок
echo "Возвращенные коды ошибок:" >> $MAILTEXT
cat $PARTLOG  | cut --fields 3 --delimiter "\"" | cut --fields 2 --delimiter " " | sort | uniq | egrep "^4|^5"  >> $MAILTEXT

# вывод всех кодов
echo "Все коды ответов:" >> $MAILTEXT
cat $PARTLOG  | cut --fields 3 --delimiter "\"" | cut --fields 2 --delimiter " " | sort | uniq -c | sort -k1 -n -r >> $MAILTEXT

# печать письма
cat $MAILTEXT

else
  echo "предыдущий процесс еще не завершился"
fi
