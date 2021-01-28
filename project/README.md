# Стенд

Для работы стенда необходимо преварительно установить на машине с Vargrant следующие модули ansible:

```bash
ansible-galaxy collection install ansible.posix
ansible-galaxy collection install community.general
```

`vagrant up` поднимает виртуальные машины и соединяет их согласно следующей топологии:

![Топология](схема.png)

Сервисы на машинах поднимаются с помощью Ansible. 

Основные компонеты ВМ:

## Общие для всех ВМ

На каждой машине добавляется репозиторий `epel-release` и устанавливается значение параметра системы `vm.swappiness = 10`.

Также ставится zabbix-агент.

## ВМ wordpressServer
Здесь устанавливаются:
- php-fpm
- nginx
- wordpress
- Клиент rsyslog

## ВМ mysqlServer
Здесь устанавливаются:
- mariadb
- Клиент rsyslog
     
## ВМ inetRouter
Здесь разрешается передача пакетов между портами и настраивается `iptables`. 

## ВМ backupsServer
Здесь устанавливается:
- borgbackup server
- rsyslog server

Для работы borg нужно создать ключ rsa и добавить публичный в `/home/vagrant/.ssh/authorized_keys backupsServer` и приватный на машины `wordpressServe` и `mysqlServer` в `/root/.ssh/borg`

и изменить его права
```bash
chown 600 /root/.ssh/borg
```

## ВМ zabbixServer
Здесь устанавливается:
- zabbix server
- nginx

### Конфигурирование Zabbix-сервера
После провижиненга ансиблом необходимо зайти на сервер и выполнить следующие команды:
```bash
zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -h 192.168.30.3 -u zabbix -p zabbix
systemctl restart zabbix-server zabbix-agent nginx php-fpm
systemctl enable zabbix-server zabbix-agent nginx php-fpm
```
Последующая конфигурация осуществляется в веб-интерфейсе Zabbix.


### Восстановление mysql из бекапа:

1. Добавить ключ от borg
2. Скопировать бекап на сервер
```bash
BORG_PASSPHRASE="otus" BORG_RSH="ssh -o 'StrictHostKeyChecking=no' -i /root/.ssh/borg" borg list vagrant@192.168.30.5:/backups/mysql

BORG_PASSPHRASE="otus" BORG_RSH="ssh -o 'StrictHostKeyChecking=no' -i /root/.ssh/borg" borg extract vagrant@192.168.30.5:/backups/mysql::2021-01-26-19-30
```
3. Восстановить базы
```bash
mysql -u root -p < var/lib/mysql/backup/all_databases.sql
```
