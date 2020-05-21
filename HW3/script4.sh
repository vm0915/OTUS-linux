#!/bin/bash
### Delete temp lvm parts after shrinking / and create lv for /home
# Delete old vg
sudo lvremove /dev/vg_root/lv_root
sudo vgremove /dev/vg_root
sudo pvremove /dev/sdb

# Create lv for /home
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
