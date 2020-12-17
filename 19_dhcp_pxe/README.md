# DHCP, PXE
В качестве шаблона воспользуемся файлами из [репозитория](https://github.com/nixuser/virtlab/tree/main/centos_pxe).

1. Для корректной работы необходимо увеличить количество оперативной памяти клиентской машины ([не менее 2048 МБ](https://bugzilla.redhat.com/show_bug.cgi?id=1314092)):
```
vb.memory = "2048"
```
2. Изменим установку с NFS на HTTP репозиторий. Для этого установим http-сервер `python3-twisted`.

Внесем изменения в скрипт, в части изменяющей файл `/var/lib/tftpboot/pxelinux/pxelinux.cfg/default`:
```
...
LABEL linux-auto
  menu label ^Auto install system
  kernel images/CentOS-8.2/vmlinuz
  append initrd=images/CentOS-8.2/initrd.img ip=enp0s3:dhcp inst.ks=http://10.0.0.20:8080/ks.cfg inst.repo=http://10.0.0.20:8080
...
```
Для более быстрой загрузки меняем ссылки на зеркала.

Собираем файлы в одной директории и раздаем по http:
```
cp /home/vagrant/cfg/ks.cfg /home/vagrant/pxe_common/
rsync -a /mnt/centos8-autoinstall/ /home/vagrant/pxe_common/
twistd  web --path /home/vagrant/pxe_common/
```

3. Запуск

Сначала запускаем и ждем полной загрузки сервера:
```
vagrant up pxeserver
```
Затем запускаем клиент:
```
vagrant up pxeclient
```
Происходит получение IP-адреса и начинается загрузка через PXE:

!(1)[images/1.png]

Выбираем нужный пункт, происходит загрузка образа и установка (в случае автоустановки):

!(2)[images/2.png]

!(3)[images/3.png]


