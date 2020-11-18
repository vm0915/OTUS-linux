#!/bin/bash
# client borgbackup

# install borgbackup
yum install -y epel-release &&
yum install -y borgbackup

# copy keys 

chmod 600 /vagrant/private_key
chown root /vagrant/script.sh
chmod 700 /vagrant/script.sh


sudo BORG_PASSPHRASE="otus" \
BORG_RSH="ssh -o 'StrictHostKeyChecking=no' -i /vagrant/private_key" \
borg create -v --stats root@192.168.11.10:/var/backup::'{now:%Y-%m-%d-%H-%M}' /etc \
2>&1 | logger &

# create cron
sudo echo "*/5 * * * * root /vagrant/script.sh" > /etc/cron.d/borg-backup 
