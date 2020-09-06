#!/bin/bash 

# передача параметра X (столько выводить ip-адресов с наибольшим количество запросов) и Y (столько выводить запрашиваемых адресов)
# при запуске скрипта
DEFAULTX=5
DEFAULTY=5

# подставить дефолтные значения, если нет переданных параметров
X=${1:-$DEFAULTX}
Y=${2:-$DEFAULTY}

# объявление переменных
# сам файл лога
LOGFILE=/vagrant/growing.log 
# часть лога для обработки
PARTLOG=/vagrant/part.log
# файл с PID 
LOCKFILE=/run/parser.pid
# директория для служебных файлов скрипта
DIR=/var/lib/parser
# файл с временем последней записи в прошлом анализе лога
TIMESTAMP=/var/lib/parser/last.timestamp
# Файл, в котором формируется письмо 
MAILTEXT=/var/lib/parser/mail.text

cleaning(){
rm -f "$LOCKFILE"; exit $?
}

if [ ! -d "$DIR" ]
  then 
  mkdir $DIR
fi

# проверка что процесс уже не идет
if (set -o noclobber; echo "$$" > "$LOCKFILE") &> /dev/null
then
  if [ -e "$LOGFILE" ]
  then
# trap на случай преждевременного завершения
trap 'cleaning' INT TERM EXIT

# узнать на каком времени закончился прошлый анализ лога
LASTTIMESTAMP=$(cat $TIMESTAMP 2> /dev/null)

if [ ! -z "$LASTTIMESTAMP" ]
  then
  # найти строчку с этим временем в файле и скопировать записи с этого момента в отдельный файл
  LINE=$(grep --line-number -F "$LASTTIMESTAMP" $LOGFILE | cut --fields 1 --delimiter ":" | head -1 )
else
  LINE=0
fi

COUNT=$(cat $LOGFILE | wc -l )
cat $LOGFILE | tail -n $(($COUNT-$LINE)) > $PARTLOG

if [ ! -s "$PARTLOG" ]
then
echo "Нет новых записей в логе с последнего анализа"
cleaning
fi
# определить последнюю временную метку в этом срезе
NEWTIMESTAMP=$(cat $PARTLOG | tail -1 | cut --fields 1 --delimiter "]" | cut --fields 2 --delimiter "[")

# добавить в письмо сведения о времени
echo "Временной диапазон:" > $MAILTEXT
echo $LASTTIMESTAMP --- $NEWTIMESTAMP >> $MAILTEXT

# вывод Х ip-адресов с наибольшим количеством запросов
echo "IP адреса с наибольшим количеством запросов:" >> $MAILTEXT
cat $PARTLOG | cut --fields 1 --delimiter " " | sort | uniq -c | sort -k1 -n -r | head -$X >> $MAILTEXT

# вывод Y наиболее запрашиваемых URI
echo "Наиболее запрашиваемые URI:" >> $MAILTEXT
cat $PARTLOG | cut --fields 2 --delimiter "\"" |  cut --fields 2 --delimiter " "| sort | uniq -c| sort -k1 -n -r | head -$Y >> $MAILTEXT

# вывод ошибок
echo "Возвращенные коды ошибок:" >> $MAILTEXT
cat $PARTLOG  | cut --fields 3 --delimiter "\"" | cut --fields 2 --delimiter " " | sort | uniq | egrep "^4|^5"  >> $MAILTEXT

# вывод всех кодов
echo "Все коды ответов:" >> $MAILTEXT
cat $PARTLOG  | cut --fields 3 --delimiter "\"" | cut --fields 2 --delimiter " " | sort | uniq -c | sort -k1 -n -r >> $MAILTEXT

# отправка письма
mail -s "Log analysis" vagrant < $MAILTEXT

# записываем время последней проанализированной записи 
echo $NEWTIMESTAMP > $TIMESTAMP
  else
    echo "Файл лога не найден"
    cleaning
fi
else
  echo "Предыдущий процесс еще не завершился"
fi
