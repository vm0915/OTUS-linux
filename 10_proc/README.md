# Управление процессами
**Домашнее задание:**
```
работаем с процессами
Задания на выбор
1) написать свою реализацию ps ax используя анализ /proc
- Результат ДЗ - рабочий скрипт который можно запустить
2) написать свою реализацию lsof
- Результат ДЗ - рабочий скрипт который можно запустить
3) дописать обработчики сигналов в прилагаемом скрипте, оттестировать, приложить сам скрипт, инструкции по использованию
- Результат ДЗ - рабочий скрипт который можно запустить + инструкция по использованию и лог консоли
4) реализовать 2 конкурирующих процесса по IO. пробовать запустить с разными ionice
- Результат ДЗ - скрипт запускающий 2 процесса с разными ionice, замеряющий время выполнения и лог консоли
5) реализовать 2 конкурирующих процесса по CPU. пробовать запустить с разными nice
- Результат ДЗ - скрипт запускающий 2 процесса с разными nice и замеряющий время выполнения и лог консоли
Критерии оценки: 5 баллов - принято - любой скрипт
+1 балл - больше одного скрипта
+2 балла все скрипты
```

**Ход выполнения:**

## Написать свою реализацию `$ps ax`

Для этого напишем скрипт анализирующий `/proc`.

`/proc` - псевдофайловая система содержащая информацию о процессах.

Вывод `ps ax` выглядит так:
```bash
PID TTY      STAT   TIME COMMAND
    1 ?        Ss     2:12 /usr/lib/systemd/systemd --system --deserialize 35
    2 ?        S      0:00 [kthreadd]
    4 ?        S<     0:00 [kworker/0:0H]
    6 ?        S      0:01 [ksoftirqd/0]

```

Наш скрипт необходимо запускать с привилегиями root для возмжности чтения `/proc`.

В начале скрипта перенаправим вывод ошибок для тех процессов, которые выдаст `ls /proc`, но к моменту парсинга уже завершат свою работу.
```bash
exec 2> /dev/null
```

Будем последовательно парсить все директории процессов (имя начинается с цифр)  в `/proc`
```bash
for PID in $(ls /proc | grep ^[0-9] | sort -g)
do
...
done
```

### TTY
Связанный терминал `$TTY` с процессом определим с помощью ссылки нулевого дескриптора в `/proc/$PID/fd`:
если ссылка указывает на файл терминала (содержит **pts/**), то запишем его в переменную, иначе запишем "**?**".
```bash
TTY=$(ls -l /proc/$PID/fd | tail --lines=+2 | head -1 | awk '{print $11}'  | cut -d "/" -f 3,4)
	if [[ ! ${TTY} =~ (pts\/).* ]]
	then
	TTY="?"
	fi
```

### STAT
Состояние процесса ($STAT) узнаем из третьего поля файла `/proc/$PID/stat`
```bash
STAT=$(cat /proc/$PID/stat | awk '{print $3}')
```

### TIME
Расчет времени ($TIME) выделен в отдельную функцию `timecalc()`. В качестве аргумента передаем ей `$PID`.

Для расчета прочитаем следующие значения из разных полей файлов `/proc/uptime` и `/proc/$PID/stat`:

`uptime` - время работы системы

`utime` - процессорное время затраченное на выполнение пользовательских инструкций (в тактах)

`stime` - процессорное время затраченное на выполение инструкций с привилегиями ядра (в тактах)

`starttime` - время старта процесса (в тактах)

`hertz` - количество тактов в секунду


Посчитаем полное время выполнения процесса в тактах и переведем его в секунды:
```bash
total_time=$((utime + stime))
seconds_total=$((total_time / hertz))
```

Переведем в удобный формат **минуты:секунды**:
```bash
minutes=$((seconds_total / 60))
seconds=$((seconds_total % 60))
TIME=$(echo "$minutes:$seconds")
```

### COMMAND
Команду, запустившую процесс, ($COMMAND) прочитаем из `/proc/$PID/cmdline`. Если этот файл пуст (вероятно процесс запущенный ядром), то возьмем значение из строки "Name:" в файле `/proc/$PID/status`:
```bash
COMMAND=$(cat /proc/$PID/cmdline)
if [ -z "$COMMAND" ]
then
COMMAND=$(cat /proc/$PID/status | grep "Name:" | awk '{print $2}')
COMMAND="["+$COMMAND+"]"
fi
```

В конце каждой итерации выводим значения переменных, разделяя на столбцы с помощью утилиты `column`:
```bash
echo "$PID;$TTY;$STAT;$TIME;$COMMAND" | column -t -s ";" 
```

