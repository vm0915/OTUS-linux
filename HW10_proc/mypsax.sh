#!/bin/bash
# Для чтения /proc необходимо иметь права root

# Перенаправим вывод ошибок 
exec 2>/dev/null

# Напечатаем заголовок таблицы
echo "PID;TTY;STAT;TIME;COMMAND" | column -t -s ";"

## Вычисление процессорного времени выделим в отдельную функцию для удобства
timecalc(){
# uptime of the system (seconds)
uptime=$(cat /proc/uptime | awk '{print $1}')

# CPU time spent in user code, measured in clock ticks
utime=$(cat /proc/$1/stat | awk '{print $14}')

# CPU time spent in kernel code, measured in clock ticks
stime=$(cat /proc/$1/stat | awk '{print $15}')

# Time when the process started, measured in clock ticks
starttime=$(cat /proc/$1/stat | awk '{print $22}')

# Hertz (number of clock ticks per second) of the system
hertz=$(getconf CLK_TCK)

# Полное время выполнения процесса в тактах
total_time=$((utime + stime))

# Полное время выполнения процесса в секундах
seconds_total=$((total_time / hertz))

# Задаем формат М:S
minutes=$((seconds_total / 60))
seconds=$((seconds_total % 60))
TIME=$(echo "$minutes:$seconds")
}

# Для всех директорий с числовым названием в /proc 
for PID in $(ls /proc | grep ^[0-9] | sort -g)
do
# Связанный с процессом терминал определим с помощью нулевого дескриптора 
TTY=$(ls -l /proc/$PID/fd | tail --lines=+2 | head -1 | awk '{print $11}'  | cut -d "/" -f 3,4)
	# Сравниваем переменную с regex выражением, чтобы понять, связан ли процесс с терминалом
	if [[ ! ${TTY} =~ (pts\/).* ]]
	then
	TTY="?"
	fi
# Смотрим состояние процесса
STAT=$(cat /proc/$PID/stat | awk '{print $3}')
# Производим расчеты времени
timecalc $PID
# Смотрим команду запустившую процесс
COMMAND=$(cat /proc/$PID/cmdline)
# Если ее нет в cmdline, то берем из строки "Name:" в файле status
if [ -z "$COMMAND" ]
then
COMMAND=$(cat /proc/$PID/status | grep "Name:" | awk '{print $2}')
COMMAND="["+$COMMAND+"]"
fi
# Выводим результат итерации, разделяя на столбцы
echo "$PID;$TTY;$STAT;$TIME;$COMMAND" | column -t -s ";" 
done
