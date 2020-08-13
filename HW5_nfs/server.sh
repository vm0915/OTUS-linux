#!/bin/bash

# Установка ПО
yum install nfs-utils -y

# Создание директории и назначение прав доступа
mkdir -p /mnt/share
chown -R vagrant:vagrant /mnt/share
chmod  555 /mnt/share
mkdir -p /mnt/share/upload
chown -R vagrant:vagrant /mnt/share/upload/
chmod  777 /mnt/share/upload/

# Объявление, что каталог для экспорта
echo "mnt/share    192.168.11.102(rw,nohide,sync,root_squash)" >> /etc/exports

# Настройка автозагрузки и запуск необходимых сервисов
systemctl enable rpcbind nfs-server firewalld
systemctl start rpcbind nfs-server firewalld

# Настройка firewall
firewall-cmd --permanent --zone=public --add-service=nfs3
firewall-cmd --permanent --zone=public --add-service=mountd
firewall-cmd --permanent --zone=public --add-service=rpc-bind
firewall-cmd --reload
