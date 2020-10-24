# SELinux
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

