#!/bin/bash
# client borgbackup

# install borgbackup
yum install -y epel-release &&
yum install -y borgbackup

# copy keys 

chmod 600 /home/vagrant/private_key
chown root /home/vagrant/script.sh
chown root /home/vagrant/private_key
chmod 700 /home/vagrant/script.sh


sudo BORG_PASSPHRASE="otus" \
BORG_RSH="ssh -o 'StrictHostKeyChecking=no' -i /home/vagrant/private_key" \
borg create -v --stats root@192.168.11.10:/var/backup::'{now:%Y-%m-%d-%H-%M}' /etc \
2>&1 | logger &

# create cron
sudo echo "*/5 * * * * root /home/vagrant/script.sh" > /etc/cron.d/borg-backup 
