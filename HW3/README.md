<<<<<<< HEAD
# Файловые системы и LVM
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
echo ***REBOOT***

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
=======
# Работа с LVM
1. Уменьшение тома под / до 8Гб  
В `script1.sh` подготавливается временный логический том с файловой системой xfs. С помощью xfsdump на новый том переносятся данные / и реконфигурируется grub для загрузки с нового места, также обновляется initrd.  
Далее необходим ребут  
В script2.sh удаляется первоначальный том и создается новый с заданным по условию размероми и создается xfs. Снова переносятся файлы и реконфигурируется grub и initrd.  
`script4.sh` среди прочего удаляет временный логический том  
  
2. Выделение тома под /var  
В `script3.sh` создается том с зеркалом, создается файловая система и копируются файлы из /var на мозданный том. Также в файле `/etc/fstab` прописывается новый том для автомонтирования.  
Далее необходим ребут  
  
3. Создание тома для снапшотов /home  
В `script4.sh` создается новый том и ФС для /home и туда копируются все файлы. Затем старая директория стирается, а новая монтируется и прописывается в `/etc/fstab`.  
В `script5.sh` демонстрируются возможности snapshot: создаются файлы, затем делается snapshot. Часть файлов удаляется, а затем восстанавливается с помощью `lvconvert --merge`
>>>>>>> cd926358a5d19473923a638ee02fec757b3c8d57
