# NFS
**Домашнее задание:**
```
Vagrant стенд для NFS или SAMBA
NFS или SAMBA на выбор:

vagrant up должен поднимать 2 виртуалки: сервер и клиент
на сервер должна быть расшарена директория
на клиента она должна автоматически монтироваться при старте (fstab или autofs)
в шаре должна быть папка upload с правами на запись
- требования для NFS: NFSv3 по UDP, включенный firewall
```

**Ход выполнения:**

В [Vagrantfile](Vagrantfile) описаны две виртуалки: клиент и сервер, каждой из которых провижинется свой скрипт.
[Скрипт](server.sh) для сервера создает дректорию с нужными правами и добавляет строку в */etc/exports*:
```bash
mnt/share    192.168.11.102(rw,nohide,sync,root_squash)
```
Также запускает и включает в автозагрузку необходимые сервисы *rpcbind nfs-server firewalld* и конфигурирует firewall
```bash
firewall-cmd --permanent --zone=public --add-service=nfs3
firewall-cmd --permanent --zone=public --add-service=mountd
firewall-cmd --permanent --zone=public --add-service=rpc-bind
firewall-cmd --reload
``` 

[Скрипт](client.sh) для клиента создает директорию, куда будет монтирование, а также конфигурирует автомонтирование в */etc/fstab* NFSv3 по UDP
```bash
192.168.11.101:/mnt/share /mnt/share nfs noauto,x-systemd.automount,proto=udp,nfsvers=3 0 0
```
и задает правила для firewall
```bash
firewall-cmd --permanent --zone=public --add-service=nfs3
firewall-cmd --permanent --zone=public --add-service=mountd
firewall-cmd --permanent --zone=public --add-service=rpc-bind
firewall-cmd --reload
```

