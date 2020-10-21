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


