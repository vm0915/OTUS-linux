#!/bin/bash

# Client and server name
CLIENT=root
SERVER=192.168.11.10

# Backup type, it may be data, system, mysql, binlogs, etc.
TYPEOFBACKUP=etc
REPOSITORY=$CLIENT@$SERVER:/var/backup/

# Backup
borg create -v --stats \
 $REPOSITORY::'{now:%Y-%m-%d-%H-%M}' \
 /etc

BORG_PASSPHRASE="otus" \
BORG_RSH="ssh -o 'StrictHostKeyChecking=no' -i /vagrant/private_key" \
borg create -v --stats $REPOSITORY::'{now:%Y-%m-%d-%H-%M}' /etc \
2>&1 | logger &


# After backup
borg prune -v --show-rc --list $REPOSITORY \
 --keep-daily=90 --keep-monthly=9
