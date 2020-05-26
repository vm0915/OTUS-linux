sudo lvremove /dev/vg_root/lv_root
sudo vgremove /dev/vg_root
sudo pvremove /dev/sdb

sudo lvcreate -n LogVol_Home -L 2G /dev/VolGroup00
sudo mkfs.xfs /dev/VolGroup00/LogVol_Home
sudo mount /dev/VolGroup00/LogVol_Home /mnt/
sudo cp -aR /home/* /mnt/
sudo rm -rf /home/*
sudo umount /mnt
sudo mount /dev/VolGroup00/LogVol_Home /home/
echo "`blkid | grep Home | awk '{print $2}'` /home xfs defaults 0 0" | sudo tee -a /etc/fstab
sudo touch /home/file{1..20}
echo "create files"
sudo ls /home/file*
sudo lvcreate -L 100MB -s -n home_snap /dev/VolGroup00/LogVol_Home
echo "remove some files"
sudo rm -f /home/file{11..20}
sudo ls /home/file*
sudo umount /home
sudo lvconvert --merge /dev/VolGroup00/home_snap
sudo mount /home
echo "recover files"
sudo ls /home/file*
