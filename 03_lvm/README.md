# Файловые системы и LVM
**Домашнее задание:**
```
Работа с LVM
на имеющемся образе
/dev/mapper/VolGroup00-LogVol00 38G 738M 37G 2% /

уменьшить том под / до 8G
выделить том под /home
выделить том под /var
/var - сделать в mirror
/home - сделать том для снэпшотов
прописать монтирование в fstab
попробовать с разными опциями и разными файловыми системами ( на выбор)
- сгенерить файлы в /home/
- снять снэпшот
- удалить часть файлов
- восстановится со снэпшота
- залоггировать работу можно с помощью утилиты script

* на нашей куче дисков попробовать поставить btrfs/zfs - с кешем, снэпшотами - разметить здесь каталог /opt
Критерии оценки: основная часть обязательна
задание со звездочкой +1 балл
```
**Ход выполнения:**

Процесс выполнения ДЗ [залогирован](typescript) программой *script*

Уменьшение ***/*** директории до 8G 

Создадим временный логический том для / и xfs на нем
```bash
# Create physical volume
sudo pvcreate /dev/sdb
# Create volume group
sudo vgcreate vg_root /dev/sdb
# Create logical volume
sudo lvcreate -n lv_root -l +100%FREE /dev/vg_root
# Create fs
sudo mkfs.xfs /dev/vg_root/lv_root
sudo mount /dev/vg_root/lv_root /mnt
```
Перенесем данные с ***/*** в ***/mnt***
```bash
sudo xfsdump -J - /dev/VolGroup00/LogVol00 | sudo xfsrestore -J - /mnt
```

Реконфигурируем ***grub***
```bash
for i in /proc/ /sys/ /dev/ /run/ /boot/; do sudo mount --bind $i /mnt/$i; done
sudo chroot /mnt/
grub2-mkconfig -o /boot/grub2/grub.cfg
```

Обновим ***initrd***
```bash
cd /boot ; for i in `ls initramfs-*img`; do sudo dracut -v $i `echo $i|sed "s/initramfs-//g;
s/.img//g"` --force; done
```
Обновим ***grub.cfg***
```bash
sudo sed -i 's/rd.lvm.lv=VolGroup00\/LogVol00/rd.lvm.lv=vg_root\/lv_root/g' /boot/grub2/grub.cfg
```
Далее ребут

Изменение размера старой volume group
```bash
# Delete old logical volume
yes 'y' | sudo lvremove /dev/VolGroup00/LogVol00

# Create new 8G logical volume
yes 'y' | sudo lvcreate -n VolGroup00/LogVol00 -L 8G /dev/VolGroup00
```

Создание *xfs*
```bash
sudo mkfs.xfs /dev/VolGroup00/LogVol00
sudo mount /dev/VolGroup00/LogVol00 /mnt
```

Перенос данных на новый логический том
```bash
sudo xfsdump -J - /dev/vg_root/lv_root | sudo xfsrestore -J - /mnt
```
Реконфигурирование ***grub***
```bash
for i in /proc/ /sys/ /dev/ /run/ /boot/; do sudo mount --bind $i /mnt/$i; done
sudo chroot /mnt/
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
```
Обновление ***initd***
```bash
cd /boot 
for i in `ls initramfs-*img`; \
do sudo dracut -v $i `echo $i|sed "s/initramfs-//g; s/.img//g"` --force; done
```
Создание ***mirror volume*** для ***/var***
Create mirror volume for /var 

Создание зеркала
```bash
sudo pvcreate /dev/sdc /dev/sdd
sudo vgcreate vg_var /dev/sdc /dev/sdd
sudo lvcreate -L 950M -m1 -n lv_var vg_var
```

Создание ФС и перенос файлов
```bash
sudo mkfs.ext4 /dev/vg_var/lv_var
sudo mount /dev/vg_var/lv_var /mnt
cp -aR /var/* /mnt/
```

Монтирование новой директории и обновление ***fstab***
```bash
sudo umount /mnt
sudo mount /dev/vg_var/lv_var /var
echo "`sudo blkid | grep var: | awk '{print $2}'` /var ext4 defaults 0 0" | sudo tee -a /etc/fstab
```
Далее ребут

Удаление временных частей lvm после уменьшения ***/*** и создание нового logical volume для ***/home***
Удаление старой vg
```bash
sudo lvremove /dev/vg_root/lv_root
sudo vgremove /dev/vg_root
sudo pvremove /dev/sdb
```

Создание lv для ***/home***
```bash
sudo lvcreate -n LogVol_Home -L 2G /dev/VolGroup00
# Create xfs
sudo mkfs.xfs /dev/VolGroup00/LogVol_Home
# Mount
sudo mount /dev/VolGroup00/LogVol_Home /mnt/
# Copy files
sudo cp -aR /home/* /mnt/
# Delete old data
sudo rm -rf /home/*
# Remount
sudo umount /mnt
sudo mount /dev/VolGroup00/LogVol_Home /home/
echo "`blkid | grep Home | awk '{print $2}'` /home xfs defaults 0 0" | sudo tee -a /etc/fstab
```

Тестирование *lvm snapshots*
```bash
# Generate files
sudo touch /home/file{1..20}
echo "create files"
sudo ls /home/file*
# Take snapshot
sudo lvcreate -L 100MB -s -n home_snap /dev/VolGroup00/LogVol_Home
# Delete some files
echo "remove some files"
sudo rm -f /home/file{11..20}
sudo ls /home/file*
# Recover from snapshot
sudo umount /home
sudo lvconvert --merge /dev/VolGroup00/home_snap
sudo mount /home
echo "recover files"
sudo ls /home/file*
```
Далее необходим ребут  
 
