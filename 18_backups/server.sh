#!/bin/bash

# init borg repo
borg init --encryption=repokey /var/backup

# create fs and mount
mkfs.xfs /dev/sdb
mount /var/backup


