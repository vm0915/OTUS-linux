#!/bin/bash
### Testing lvm snapshots
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
