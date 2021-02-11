# Iptables
**Домашнее задание:**
```
Сценарии iptables
1) реализовать knocking port
- centralRouter может попасть на ssh inetrRouter через knock скрипт
пример в материалах
2) добавить inetRouter2, который виден(маршрутизируется (host-only тип сети для виртуалки)) с хоста 
или форвардится порт через локалхост
3) запустить nginx на centralServer
4) пробросить 80й порт на inetRouter2 8080
5) дефолт в инет оставить через inetRouter

* реализовать проход на 80й порт без маскарадинга
```

**Ход выполнения:**

**1. Knocking port**

Суть port knocking состоит в обращении к нескольким определенным портам последовательно, чтобы открыть нужный порт.

Для реализации такого механизма используем пакеты `iptables`, `iptables-services`.

Если пакет приходит на первый порт последовательности то записываем его в список SSH0:
```
-A TRAFFIC -p tcp -m state --state NEW -m tcp --dport 5160 -m recent --set --name SSH0 --mask 255.255.255.255 --rsource -j DROP
```
Если приходит второй пакет с того же ip на этот же порт, то удаляем его из списка:
```
-A TRAFFIC -p tcp -m state --state NEW -m tcp -m recent --remove --name SSH0 --mask 255.255.255.255 --rsource -j DROP
```
Затем повторяем тоже самое для следующих портов, но с проверкой что ip есть в списке для предыдущего порта последовательности:
```
-A TRAFFIC -p tcp -m state --state NEW -m tcp --dport 9845 -m recent --rcheck --name SSH0 --mask 255.255.255.255 --rsource -j SSH-INPUT
```
Если все нужные обращения к портам были, то обкрываем ssh для этого ip на 30 секунд, а также имеем правило на разрешение пакетов для уже установленных сессий, чтобы через 30 секунд работа с ssh не прервалась:
```
-A TRAFFIC -m state --state RELATED,ESTABLISHED -j ACCEPT
-A TRAFFIC -p tcp -m state --state NEW -m tcp --dport 22 -m recent --rcheck --seconds 30 --name SSH2 --mask 255.255.255.255 --rsource -j ACCEPT
```
Копируем на *centralRouter* скрипт для проверки port knocking:
```
#!/bin/bash
HOST=$1
shift
for ARG in "$@"
do
        nmap -Pn --host-timeout 100 --max-retries 0 -p $ARG $HOST
done
```

Проверяем:
```
[vagrant@centralRouter ~]$ sudo /vagrant/knock.sh 192.168.255.1 5160 9845 7652

Starting Nmap 6.40 ( http://nmap.org ) at 2020-12-22 10:28 UTC
Warning: 192.168.255.1 giving up on port because retransmission cap hit (0).
Nmap scan report for 192.168.255.1
Host is up (0.00056s latency).
PORT     STATE    SERVICE
5160/tcp filtered unknown
MAC Address: 08:00:27:31:02:CE (Cadmus Computer Systems)

Nmap done: 1 IP address (1 host up) scanned in 0.29 seconds

Starting Nmap 6.40 ( http://nmap.org ) at 2020-12-22 10:28 UTC
Warning: 192.168.255.1 giving up on port because retransmission cap hit (0).
Nmap scan report for 192.168.255.1
Host is up (0.00061s latency).
PORT     STATE    SERVICE
9845/tcp filtered unknown
MAC Address: 08:00:27:31:02:CE (Cadmus Computer Systems)

Nmap done: 1 IP address (1 host up) scanned in 0.32 seconds

Starting Nmap 6.40 ( http://nmap.org ) at 2020-12-22 10:28 UTC
Warning: 192.168.255.1 giving up on port because retransmission cap hit (0).
Nmap scan report for 192.168.255.1
Host is up (0.00049s latency).
PORT     STATE    SERVICE
7652/tcp filtered unknown
MAC Address: 08:00:27:31:02:CE (Cadmus Computer Systems)

Nmap done: 1 IP address (1 host up) scanned in 0.31 seconds
```
Авторизироватся не нужно, ответа от демона ssh достаточно чтобы понять что порт открыт:
```
ssh vagrant@192.168.255.1
Permission denied (publickey,gssapi-keyex,gssapi-with-mic).
```


**2. Forward порта**

Поднимаем nginx на *centralServer*. 

Создаем новый роутер *inetRouter2*. Прописываем на нем нужные маршруты и делаем форвард порта:
```
iptables -t nat -A PREROUTING -i eth2 -p tcp --dport 8080 -j DNAT --to 192.168.0.2:80
iptables -t nat -A POSTROUTING  -p tcp --dst 192.168.0.2 --dport 80 -j SNAT --to-source 192.168.254.1
```
То есть в цепочке PREROUTING таблицы nat мы подменяем адрес назначения и порт, а затем в цепочке POSTROUTING делаем трансляцию адресов источника, чтобы пакету было куда вернуться.

Проверяем с хостовой машины:
```
[root@srv-centos-test 20_iptables]# curl -I 192.168.10.10:8080
HTTP/1.1 200 OK
Server: nginx/1.16.1
Date: Tue, 22 Dec 2020 10:36:04 GMT
Content-Type: text/html
Content-Length: 4833
Last-Modified: Fri, 16 May 2014 15:12:48 GMT
Connection: keep-alive
ETag: "53762af0-12e1"
Accept-Ranges: bytes
```



