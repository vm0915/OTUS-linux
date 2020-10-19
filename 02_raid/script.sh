#!/bin/bash

# Display disks
sudo lsblk

# Зануление суперблоков
sudo mdadm --zero-superblock --force /dev/sd{b,c,d,e,f}

# Создание рейда
sudo mdadm --create --verbose /dev/md0 -l 5 -n 5 /dev/sd{b,c,d,e,f}

# Проверка что RAID собрался
sudo cat /proc/mdstat
sudo mdadm -D /dev/md0

# Проверка и создание mdadm.conf
sudo mdadm --detail --scan --verbose

sudo mkdir /etc/mdadm

sudo echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
sudo mdadm --detail --scan --verbose | awk '/ARRAY/{print}' >> /etc/mdadm/mdadm.conf

