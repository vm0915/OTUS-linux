#!/bin/bash

# Client and server name
CLIENT=root
SERVER=192.168.11.10

# Backup type, it may be data, system, mysql, binlogs, etc.
TYPEOFBACKUP=etc
REPOSITORY=$CLIENT@$SERVER:/var/backup/$(hostname)-${TYPEOFBACKUP}

# Backup
borg create -v --stats \
 $REPOSITORY::'{now:%Y-%m-%d-%H-%M}' \
 /etc

# After backup
borg prune -v --show-rc --list $REPOSITORY \
 --keep-daily=90 --keep-monthly=9
