#!/bin/bash

# Установка ПО
yum install nfs-utils -y

# Создание директории и назначение прав
mkdir -p /mnt/share
chown -R vagrant:vagrant /mnt/share/

# Конфигурируем fstab
echo "192.168.11.101:/mnt/share /mnt/share nfs noauto,x-systemd.automount,proto=udp,nfsvers=3 0 0" >> /etc/fstab

# Настройка автозагрузки и запуск необходимых сервисов
systemctl enable rpcbind firewalld
systemctl start rpcbind firewalld

# Настройка firewall
firewall-cmd --permanent --zone=public --add-service=nfs3
firewall-cmd --permanent --zone=public --add-service=mountd
firewall-cmd --permanent --zone=public --add-service=rpc-bind
firewall-cmd --reload

# Перезагрузка
shutdown -r now
