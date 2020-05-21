#!/bin/bash
### Shrink / directory to 8G (part 2)
# check new / mountpoint
lsblk

## Change size of old volume group
# Delete old logical volume
yes 'y' | sudo lvremove /dev/VolGroup00/LogVol00

# Create new 8G logical volume
yes 'y' | sudo lvcreate -n VolGroup00/LogVol00 -L 8G /dev/VolGroup00
##

# Create xfs
sudo mkfs.xfs /dev/VolGroup00/LogVol00
sudo mount /dev/VolGroup00/LogVol00 /mnt

# Copy / to new lv
sudo xfsdump -J - /dev/vg_root/lv_root | sudo xfsrestore -J - /mnt

# Reconfigure grub
for i in /proc/ /sys/ /dev/ /run/ /boot/; do sudo mount --bind $i /mnt/$i; done
sudo chroot /mnt/
sudo grub2-mkconfig -o /boot/grub2/grub.cfg

cd /boot 
for i in `ls initramfs-*img`; \
do sudo dracut -v $i `echo $i|sed "s/initramfs-//g; s/.img//g"` --force; done


