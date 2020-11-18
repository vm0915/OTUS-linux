#!/bin/bash
# client borgbackup

# install borgbackup
yum install -y epel-release &&
yum install -y borgbackup

# copy keys 
eval $(ssh-agent -s)
ssh-add ~/.ssh/id_rsa1

ssh -o "StrictHostKeyChecking=no" root@192.168.11.10

BORG_RSH
BORG_PASSPHRASE="otus" BORG_RSH="ssh -i /home/vagrant/.ssh/id_rsa1" borg create -v --stats root@192.168.11.10:/var/backup::'{now:%Y-%m-%d-%H-%M}' /etc

# create cron
