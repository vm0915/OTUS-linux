# ZFS
Домашнее задание:
```
Практические навыки работы с ZFS
Цель: Отрабатываем навыки работы с созданием томов export/import и установкой параметров.

Определить алгоритм с наилучшим сжатием.
Определить настройки pool’a
Найти сообщение от преподавателей

Результат:
список команд которыми получен результат с их выводами
1. Определить алгоритм с наилучшим сжатием

Зачем:
Отрабатываем навыки работы с созданием томов и установкой параметров. Находим наилучшее сжатие.


Шаги:
- определить какие алгоритмы сжатия поддерживает zfs (gzip gzip-N, zle lzjb, lz4)
- создать 4 файловых системы на каждой применить свой алгоритм сжатия
Для сжатия использовать либо текстовый файл либо группу файлов:
- скачать файл “Война и мир” и расположить на файловой системе
wget -O War_and_Peace.txt http://www.gutenberg.org/ebooks/2600.txt.utf-8
либо скачать файл ядра распаковать и расположить на файловой системе

Результат:
- список команд которыми получен результат с их выводами
- вывод команды из которой видно какой из алгоритмов лучше


2. Определить настройки pool’a

Зачем:
Для переноса дисков между системами используется функция export/import. Отрабатываем навыки работы с файловой системой ZFS

Шаги:
- Загрузить архив с файлами локально.
https://drive.google.com/open?id=1KRBNW33QWqbvbVHa3hLJivOAt60yukkg
Распаковать.
- С помощью команды zfs import собрать pool ZFS.
- Командами zfs определить настройки
- размер хранилища
- тип pool
- значение recordsize
- какое сжатие используется
- какая контрольная сумма используется
Результат:
- список команд которыми восстановили pool . Желательно с Output команд.
- файл с описанием настроек settings

3. Найти сообщение от преподавателей

Зачем:
для бэкапа используются технологии snapshot. Snapshot можно передавать между хостами и восстанавливать с помощью send/receive. Отрабатываем навыки восстановления snapshot и переноса файла.

Шаги:
- Скопировать файл из удаленной директории. https://drive.google.com/file/d/1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG/view?usp=sharing
Файл был получен командой
zfs send otus/storage@task2 > otus_task2.file
- Восстановить файл локально. zfs receive
- Найти зашифрованное сообщение в файле secret_message

Результат:
- список шагов которыми восстанавливали
- зашифрованное сообщение
```

# Выполнение

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
## 1. Определить алгоритм с наилучшим сжатием
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
## 2. Определить настройки pool’a
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
## 3. Найти сообщение от преподавателей
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
