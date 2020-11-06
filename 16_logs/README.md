# Сбор и анализ логов
Vagrant поднимает две виртуалки: web-сервер (с бегущим nginx и аудитом изменений /etc/nginx) и log-сервер, куда будут передаваться логи с помощью rsyslog.
## Log-сервер
Изменяем файл `/etc/rsyslog.conf`, добавляя строки:
```bash
$ModLoad imudp           # принимаем по UDP
$UDPServerRun 514
$ModLoad imtcp           # принимаем по TCP
$InputTCPServerRun 514
```
И добавляем шаблон в `/etc/rsyslog.d/remote.conf` для разделения прилетающих логов по файлам:
```bash
$template DynamicFile,"/var/log/loghost/%HOSTNAME%/%syslogfacility-text%.log"
*.*    ?DynamicFile
```
После чего перезапускаем демона rsyslog.

## Web-сервер
Устанавливаем nginx из epel-release.

Включаем аудит изменений конфига nginx:
```bash
auditctl -w /etc/nginx/ -p wa -k nginx_conf
```
`-w` - директория для отслеживания

`-p wa` - следим за запись и изменением атрибутов

`-k nginx_conf` - метка события

SELinux будет мешать читать rsyslogd файлы из /vag/log/audit, для простоты его отключим.

Изменяем `/etc/rsyslog.conf`:
```bash
*.crit              @@192.168.11.101    # @@ означает передачи по TCP
*.crit              /var/log/crit       # все критические логи храним еще и локально
local3.*            @192.168.11.101     # @ означает передачу по UPD, а local3 используем для логов nginx
```

Так как логи nginx локально храниться не должны, правим директивы в `/etc/nginx/nginx.conf`:
```bash
...
error_log syslog:server=192.168.11.101,facility=local3,tag=nginx,severity=error;
...
access_log syslog:server=192.168.11.101,facility=local3,tag=nginx,severity=info;
...
```
Перезапускаем rsyslog и включаем nginx.

Для проверки делаем запросы и смотрим реакцию на сервере:
```bash
[root@web vagrant]# curl -I localhost
[root@log vagrant]# cat /var/log/loghost/web/local3.log
Nov  6 19:27:53 web nginx: ::1 - - [06/Nov/2020:19:27:53 +0000] "HEAD / HTTP/1.1" 200 0 "-" "curl/7.29.0"

[root@web vagrant]# echo test123 | logger --priority user.crit
[root@log vagrant]# cat /var/log/loghost/web/user.log
Nov  6 19:27:54 web vagrant: test123
```
