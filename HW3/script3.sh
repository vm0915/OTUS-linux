#!/bin/bash
### Create mirror volume for /var 

# Create mirror
sudo pvcreate /dev/sdc /dev/sdd
sudo vgcreate vg_var /dev/sdc /dev/sdd
sudo lvcreate -L 950M -m1 -n lv_var vg_var

# Create FS and copy /var to new place
sudo mkfs.ext4 /dev/vg_var/lv_var
sudo mount /dev/vg_var/lv_var /mnt
cp -aR /var/* /mnt/

# Saving data for backup
sudo mkdir /tmp/oldvar && sudo mv /var/* /tmp/oldvar

# Mount new directory and update fstab
sudo umount /mnt
sudo mount /dev/vg_var/lv_var /var
echo "`blkid | grep var: | awk '{print $2}'` /var ext4 defaults 0 0" | sudo tee -a /etc/fstab

# Reboot by vagrant plugin
echo ***REBOOT***

