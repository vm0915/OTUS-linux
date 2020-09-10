#!/bin/bash

exec 2>/dev/null

echo "PID;TTY;STAT;TIME;COMMAND" | column -t -s ";"

timecalc(){
# uptime of the system (seconds)
uptime=$(cat /proc/uptime | awk '{print $1}')

# CPU time spent in user code, measured in clock ticks
utime=$(cat /proc/$1/stat | awk '{print $14}')

# CPU time spent in kernel code, measured in clock ticks
stime=$(cat /proc/$1/stat | awk '{print $15}')

# Waited-for children's CPU time spent in user code (in clock ticks)
cutime=$(cat /proc/$1/stat | awk '{print $16}')

# Waited-for children's CPU time spent in kernel code (in clock ticks)
cstime=$(cat /proc/$1/stat | awk '{print $17}')

# Time when the process started, measured in clock ticks
starttime=$(cat /proc/$1/stat | awk '{print $22}')

# Hertz (number of clock ticks per second) of the system
hertz=$(getconf CLK_TCK)

#total_time=$(echo $utime $stime | awk '{print $1 + $2}')
#total_time=$(echo $total_time $cutime $cstime | awk '{print $1 + $2 + $3}')
#seconds=$((uptime - (starttime / Hertz)))
#seconds=$(echo $uptime $starttime $hertz | awk '{print ($1 - $2 / $3)}')
# cpu_usage = 100 * ((total_time / Hertz) / seconds)
total_time=$((utime + stime))
seconds_total=$((total_time / hertz))
minutes=$((seconds_total / 60))
seconds=$((seconds_total % 60))
TIME=$(echo "$minutes:$seconds")

}

for PID in $(ls /proc | grep ^[0-9] | sort -g)
do
TTY=$(ls -l /proc/$PID/fd | tail --lines=+2 | head -1 | awk '{print $11}'  | cut -d "/" -f 3,4)
	if [[ ! ${TTY} =~ (pts\/).* ]]
	then
	TTY="?"
	fi
STAT=$(cat /proc/$PID/stat | awk '{print $3}')
timecalc $PID
COMMAND=$(cat /proc/$PID/cmdline)
if [ -z "$COMMAND" ]
then
COMMAND=$(cat /proc/$PID/status | grep "Name:" | awk '{print $2}')
COMMAND="["+$COMMAND+"]"
fi
echo "$PID;$TTY;$STAT;$TIME;$COMMAND" | column -t -s ";" 
done
echo $TEXT | column -t -s ";"
