#!/bin/bash
sudo yum install -y epel-release
sudo yum install -y borgbackup

sudo mkdir /var/backup

# create fs and mount
sudo mkfs.xfs /dev/sdb
sudo mount /dev/sdb /var/backup

# init borg repo
sudo BORG_PASSPHRASE="otus" borg init --encryption=repokey /var/backup




