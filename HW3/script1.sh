#!/bin/bash
### Shrink / directory to 8G (part 1)

# Install xfsdump
sudo yum install -y xfsdump

## Create temporary logical volume for / and xfs on it
# Create physical volume
sudo pvcreate /dev/sdb
# Create volume group
sudo vgreate vg_root /dev/sdb
# Create logical volume
sudo lvcreate -n lv_root -l +100%FREE /dev/vg_root
# Create fs
sudo mkfs.xfs /dev/vg_root/lv_root
sudo mount /dev/vg_root/lv_root /mnt
##

# Copy data from / to /mnt
sudo xfsdump -J - /dev/VolGroup00/LogVol00 | sudo xfsrestore -J - /mnt

# Reconfigure grub
for i in /proc/ /sys/ /dev/ /run/ /boot/; do sudo mount --bind $i /mnt/$i; done
sudo chroot /mnt/
grub2-mkconfig -o /boot/grub2/grub.cfg

# Update initrd
cd /boot ; for i in `ls initramfs-*img`; do sudo dracut -v $i `echo $i|sed "s/initramfs-//g;
s/.img//g"` --force; done

# Update grub.cfg
sudo sed -i 's/rd.lvm.lv=VolGroup00\/LogVol00/rd.lvm.lv=vg_root\/lv_root/g' /boot/grub2/grub.cfg

# reboot by vagrant plugin
echo ***REBOOT***

