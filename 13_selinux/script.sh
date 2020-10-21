sudo yum install epel-release -y
sudo yum install nginx -y

sudo sed -i "s/listen\s\+80/listen 5500/" /etc/nginx/nginx.conf
sudo nginx -t

sudo systemctl start nginx

# sealert
sudo yum install -y setroubleshoot-server 
# seinfo
sudo yum install -y setools-console

sudo sealert -a /var/log/audit/audit.log

setsebool -P nis_enabled 1

sudo systemctl start nginx

sudo ss -natupl | grep 5500
