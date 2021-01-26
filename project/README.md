Установка необходимых модулей ansible на хосте
```bash
ansible-galaxy collection install ansible.posix
ansible-galaxy collection install community.general
```

для работы borg нужно создать ключ rsa и добавить публичный в /home/vagrant/.ssh/authorized_keys backupsServer и приватный на машины wordpressServer и mysqlServer в /root/.ssh/borg 

и изменить его права
```bash
chown 600 /root/.ssh/borg
```

Восстановление mysql из бекапа:

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
