#!/bin/bash

sudo su root
yum install -y epel-release
yum install -y nginx

cp /vagrant/rsyslog_web.conf /etc/rsyslog.conf
cp /vagrant/nginx_log.conf /etc/rsyslog.d/nginx.conf
cp /vagrant/nginx.conf /etc/nginx/nginx.conf

auditctl -w /etc/nginx/ -p wa -k nginx_conf

setenforce 0

systemctl restart rsyslog
systemctl start nginx

curl -I localhost
echo test123 | logger --priority user.crit
