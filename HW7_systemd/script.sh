#!/bin/bash

# 1
sudo cp /vagrant/monitoring.sh /opt/
sudo cp /vagrant/monitoring.service /etc/systemd/system/
sudo cp /vagrant/monitoring.timer /etc/systemd/system/
sudo cp /vagrant/monitoring /etc/sysconfig/monitoring

sudo chmod u+x /opt/monitoring.sh

sudo systemctl enable monitoring.timer
sudo systemctl start monitoring.timer

# 3
sudo yum install -y httpd

sudo mv /usr/lib/systemd/system/httpd.service /usr/lib/systemd/system/httpd@.service
sudo cp /usr/lib/systemd/system/httpd@.service /usr/lib/systemd/system/httpd@1.service
sudo cp /usr/lib/systemd/system/httpd@.service /usr/lib/systemd/system/httpd@2.service

sudo sed -i '/ExecStart/ s/$/ -f conf\/httpd@1.conf/' /usr/lib/systemd/system/httpd@1.service
sudo sed -i '/Description=/c\Description=Apache Web Server Instance 1' /usr/lib/systemd/system/httpd@1.service
sudo sed -i '/ExecStart/ s/$/ -f conf\/httpd@2.conf/' /usr/lib/systemd/system/httpd@2.service
sudo sed -i '/Description=/c\Description=Apache Web Server Instance 2' /usr/lib/systemd/system/httpd@2.service

sudo cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd@1.conf
sudo cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd@2.conf

sudo sed -i '/^ServerRoot/ s/$/\nPidFile \/var\/run\/httpd\@1.pid/' /etc/httpd/conf/httpd@1.conf
sudo sed -i '/^ServerRoot/ s/$/\nPidFile \/var\/run\/httpd\@2.pid/' /etc/httpd/conf/httpd@2.conf

sudo sed -i.bak '/^Listen/c\Listen 7777' /etc/httpd/conf/httpd@1.conf
sudo sed -i.bak '/^Listen/c\Listen 8888' /etc/httpd/conf/httpd@2.conf

sudo yum install -y policycoreutils-python
sudo semanage port -a -t http_port_t -p tcp 7777
sudo semanage port -a -t http_port_t -p tcp 8888

sudo systemctl daemon-reload
sudo systemctl enable httpd@1.service httpd@2.service
sudo systemctl start httpd@1.service httpd@2.service
