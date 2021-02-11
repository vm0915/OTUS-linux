# SELinux
**Домашнее задание:**
```
Практика с SELinux
Цель: Тренируем умение работать с SELinux: диагностировать проблемы и модифицировать политики SELinux 
для корректной работы приложений, если это требуется.
1. Запустить nginx на нестандартном порту 3-мя разными способами:
- переключатели setsebool;
- добавление нестандартного порта в имеющийся тип;
- формирование и установка модуля SELinux.
К сдаче:
- README с описанием каждого решения (скриншоты и демонстрация приветствуются).

2. Обеспечить работоспособность приложения при включенном selinux.
- Развернуть приложенный стенд
https://github.com/mbfx/otus-linux-adm/tree/master/selinux_dns_problems
- Выяснить причину неработоспособности механизма обновления зоны (см. README);
- Предложить решение (или решения) для данной проблемы;
- Выбрать одно из решений для реализации, предварительно обосновав выбор;
- Реализовать выбранное решение и продемонстрировать его работоспособность.
К сдаче:
- README с анализом причины неработоспособности, возможными способами решения и обоснованием выбора одного из них;
- Исправленный стенд или демонстрация работоспособной системы скриншотами и описанием.
Критерии оценки:
Обязательно для выполнения:
- 1 балл: для задания 1 описаны, реализованы и продемонстрированы все 3 способа решения;
- 1 балл: для задания 2 описана причина неработоспособности механизма обновления зоны;
- 1 балл: для задания 2 реализован и продемонстрирован один из способов решения;
Опционально для выполнения:
- 1 балл: для задания 2 предложено более одного способа решения;
- 1 балл: для задания 2 обоснованно(!) выбран один из способов решения.
```

**Ход выполнения:**

## 1. Запустить NGINX на нестандартном порту 
### Переключатели setsebool; формирование и установка модуля SELinux
Заменяем порт в конфигах NGINX, проверям синтаксис и запускаем
```bash
sudo sed -i "s/listen\s\+80/listen 5500/" /etc/nginx/nginx.conf
sudo nginx -t
```
`journalctl -xe` показывает что при старте возникла ошибка:
```
nginx: [emerg] bind() to 0.0.0.0:5500 failed (13: Permission denied)
```
Проверяем проблемы в `/var/log/audit/audit.log` 
```bash
sealert -a /var/log/audit/audit.log
SELinux is preventing /usr/sbin/nginx from name_bind access on the tcp_socket port 5500.
```

И получаем два предложения для решения проблемы:
- Изменить SE boolean
```bash
...
If you want to allow httpd to use openstack
Then you must tell SELinux about this by enabling the 'httpd_use_openstack' boolean.

Do
setsebool -P nis_enabled 1
...
```
- Сгенерировать модуль с политикой
```bash
You can generate a local policy module to allow this access.
Do
allow this access for now by executing:
# ausearch -c 'nginx' --raw | audit2allow -M my-nginx
# semodule -i my-nginx.pp
```

### Добавление порта в существующий тип
Так можно увидеть привязку портов к типам:
```bash
[root@selinuxvm vagrant]# semanage port -l | grep http
http_cache_port_t              tcp      8080, 8118, 8123, 10001-10010
http_cache_port_t              udp      3130
http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
pegasus_https_port_t           tcp      5989
```
Добавим к `http_port_t` новый порт:
```bash
semanage port -a -t http_port_t -p tcp 5500
```
Параметры:

`port` - Manage network port type definitions

`-a` - Add a record of the specified object type

`-t` - SELinux type for the object

`-p` - Protocol for the specified port (tcp|udp) or internet protocol version  for  the  specified  node (ipv4|ipv6)

## 2. Обеспечить работоспособность приложения
Развернем [стенд](selinux_dns_problems) и проверим работу после `setenforce 0` на сервере:
```bash
[vagrant@client ~]$ nsupdate -k /etc/named.zonetransfer.key
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
> quit
```

Возвращаем `setenforce 1`, снова пытаемся сделать запись с client и смотрим логи `named.service`:
```bash
[root@ns01 vagrant]# journalctl -xe -u named
...
Oct 24 10:06:16 ns01 named[5005]: /etc/named/dynamic/named.ddns.lab.view1.jnl: open: permission denied
...
```
Запускаем `sealert -a /var/log/audit/audit.log`, где узнаем причину:
```bash
SELinux is preventing /usr/sbin/named from write access on the file named.ddns.lab.view1.jnl.
```
 Читаем про типы SELinux для named [здесь](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html-single/selinux_users_and_administrators_guide/index#sect-Managing_Confined_Services-BIND-Types), узнаем контекст безопасности файла:
 ```bash
 [root@ns01 vagrant]# ls -Z /etc/named/dynamic/named.ddns.lab.view1.jnl
-rw-r--r--. named named system_u:object_r:etc_t:s0       /etc/named/dynamic/named.ddns.lab.view1.jnl
```
и приходим к следующим возможным решениям проблемы:
1. создать разрешающий модуль с помощью `ausearch -c 'isc-worker0000' --raw | audit2allow -M my-iscworker0000` и установить его. 
Модуль будет иметь следующее содержание:
```bash
[root@ns01 vagrant]# cat my-iscworker0000.te

module my-iscworker0000 1.0;

require {
        type etc_t;
        type named_t;
        class file { create write };
}

#============= named_t ==============

#!!!! WARNING: 'etc_t' is a base type.
allow named_t etc_t:file { create write };
```
что позволит файлам с меткой `named_t` слишком многое

2. Изменить контекст безопасности для папок и подпапок `/etc/named/`. Это много работы.

3. Переметить файлы в зон в стандартные директории, где они при копировании получат стандартные метки, изменить их владельца. Поправить конфиги, которые ссылались на старые пути и перезапустить демона.
Найти конфиги можно с помощью `grep -R /etc/named /etc`
```bash
[root@ns01 vagrant]# cp -R /etc/named /var/
[root@ns01 vagrant]# chown named:named -R /var/named
[root@ns01 vagrant]# sed -i.bk 's+/etc/named/+/var/named/+g' /etc/named.conf
[root@ns01 vagrant]# systemctl daemon-reload
[root@ns01 vagrant]# systemctl restart named
```
Исполняем третий вариант и сервер выдает корректный ответ:
```bash
[vagrant@client ~]$ dig @192.168.50.10 www.ddns.lab
...
;; ANSWER SECTION:
www.ddns.lab.           60      IN      A       192.168.50.15
...
```

