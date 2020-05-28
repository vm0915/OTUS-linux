#ZFS
Установка zfs
```bash
$ sudo yum install -y yum-utils
$ sudo yum install http://download.zfsonlinux.org/epel/zfs-release.el8_0.noarch.rpm
$ sudo gpg --quiet --with-fingerprint /etc/pki/rpm-gpg/RPM-GPG-KEY-zfsonlinux
$ sudo yum-config-manager --enable zfs-kmod
$ sudo yum-config-manager --disable zfs
$ sudo yum repolist --enabled | grep zfs && echo ZFS repo enabled
$ sudo yum install -y zfs
```
Загрузить **zfs modules**
```bash
$ sudo /sbin/modprobe zfs
```
##1 Определить алгоритм с наилучшим сжатием
Возможные алгоритмы сжатия
```bash
compression=on|off|gzip|gzip-N|lz4|lzjb|zle
```
Создать **zpool** и 4 файловые системы с разным алгоритмом сжатия
```bash
$ sudo zpool create mypool sdb sdc sdd sde
$ sudo zpool list
NAME     SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
mypool  13.2G  94.5K  13.2G        -         -     0%     0%  1.00x    ONLINE  -
```
```bash
$ sudo zfs create mypool/data1 -o compression=gzip
$ sudo zfs create mypool/data2 -o compression=lz4
$ sudo zfs create mypool/data3 -o compression=lzjb
$ sudo zfs create mypool/data4 -o compression=zle
$ sudo zfs list
NAME           USED  AVAIL     REFER  MOUNTPOINT
mypool         238K  12.8G       28K  /mypool
mypool/data1    24K  12.8G       24K  /mypool/data1
mypool/data2    24K  12.8G       24K  /mypool/data2
mypool/data3    24K  12.8G       24K  /mypool/data3
mypool/data4    24K  12.8G       24K  /mypool/data4
```
Сравним алгоритмы
```bash
$ sudo zfs list -o name,compression,compressratio
NAME          COMPRESS  RATIO
mypool              on  1.07x
mypool/data1      gzip  1.08x
mypool/data2       lz4  1.08x
mypool/data3      lzjb  1.07x
mypool/data4       zle  1.08x
```
##2 Определить настройки pool’a
Импортируем zpool
```bash
$ sudo zpool import -d .
   pool: otus
     id: 6554193320433390805
  state: ONLINE
 action: The pool can be imported using its name or numeric identifier.
 config:

	otus                                      ONLINE
	  mirror-0                                ONLINE
	    /vagrant/zfs_task1/zpoolexport/filea  ONLINE
	    /vagrant/zfs_task1/zpoolexport/fileb  ONLINE
$ sudo zpool import otus -d .
$ sudo zpool list
NAME     SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
mypool  13.2G  5.65M  13.2G        -         -     0%     0%  1.00x    ONLINE  -
otus     480M  2.18M   478M        -         -     0%     0%  1.00x    ONLINE  -
```
Определим параметры ([все](settings.txt))
```bash
$ sudo zfs get name,available,type,recordsize,compression,checksum otus
NAME  PROPERTY     VALUE       SOURCE
otus  name         otus        -
otus  available    350M        -
otus  type         filesystem  -
otus  recordsize   128K        local
otus  compression  zle         local
otus  checksum     sha256      local
```
##3 Найти сообщение от преподавателей
Восстанавливаем снапшот
```bash
$ sudo zfs receive otus/storage@snap1 < otus_task2.file 
$ sudo zfs list | grep otus/storage
otus/storage    2.85M   347M     2.83M  /otus/storage
```
Просмотр сообщения
```bash
$ sudo cat /otus/storage/task1/file_mess/secret_message 
https://github.com/sindresorhus/awesome
``` 
