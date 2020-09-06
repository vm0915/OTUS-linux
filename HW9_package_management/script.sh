#!/bin/bash

sudo su -l root

# Установим необходимое ПО
yum install -y epel-release createrepo rpmdevtools tree
yum install -y nginx

# Создаем RPM build tree в домашней директории
#rpmdev-setuptree
#tree -d -L 1 /root/rpmbuild

# Устанавливаем необходимое для билда ПО
yum-builddep /vagrant/clogtail/clogtail.spec -y

# Создаем RPM
rpmbuild -bb /vagrant/clogtail/clogtail.spec
tree /root/rpmbuild/

# Запускаем nginx
systemctl start nginx
systemctl status nginx
mkdir /usr/share/nginx/html/repo
cp /root/rpmbuild/RPMS/x86_64/clogtail-0.3.0-2.el7.x86_64.rpm /usr/share/nginx/html/repo/
createrepo /usr/share/nginx/html/repo/

# Поправить конфиг nginx /etc/nginx/nginx.conf
VAR=$(grep -n location /etc/nginx/nginx.conf | head -1 | awk 'BEGIN { FS = ":" } ; {print $1}')
sed -i "$(($VAR+1)) i root /usr/share/nginx/html;\n\tindex index.html index.htm; \n\tautoindex on;" /etc/nginx/nginx.conf
nginx -t
nginx -s reload

# Проверям nginx отдает rpm
curl -a http://localhost/repo/

# Добавляем репозиторий в yum
cat >> /etc/yum.repos.d/otus.repo << EOF
[otus]
name=otus-linux
baseurl=http://localhost/repo
gpgcheck=0
enabled=1
EOF

# Проверяем и устанавливаем из него clogtail
yum repolist enabled | grep otus
yum install clogtail -y
type clogtail
