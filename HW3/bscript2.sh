lsblk
yes 'y' | sudo lvremove /dev/VolGroup00/LogVol00
yes 'y' | sudo lvcreate -n VolGroup00/LogVol00 -L 8G /dev/VolGroup00
sudo mkfs.xfs /dev/VolGroup00/LogVol00
sudo mount /dev/VolGroup00/LogVol00 /mnt
sudo xfsdump -J - /dev/vg_root/lv_root | sudo xfsrestore -J - /mnt
for i in /proc/ /sys/ /dev/ /run/ /boot/; do sudo mount --bind $i /mnt/$i; done
sudo chroot /mnt/
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
cd /boot 
for i in `ls initramfs-*img`; \
do sudo dracut -v $i `echo $i|sed "s/initramfs-//g; s/.img//g"` --force; done
sudo pvcreate /dev/sdc /dev/sdd
sudo vgcreate vg_var /dev/sdc /dev/sdd
sudo lvcreate -L 950M -m1 -n lv_var vg_var
sudo mkfs.ext4 /dev/vg_var/lv_var
sudo mount /dev/vg_var/lv_var /mnt
cp -aR /var/* /mnt/
sudo mkdir /tmp/oldvar && sudo mv /var/* /tmp/oldvar
sudo umount /mnt
sudo mount /dev/vg_var/lv_var /var
echo "`blkid | grep var: | awk '{print $2}'` /var ext4 defaults 0 0" | sudo tee -a /etc/fstab
echo ***REBOOT***
