#/bin/bash

# Создание группы и пользователей
sudo groupadd admin
sudo useradd theadmin -G admin
sudo useradd user
echo "otus1" | sudo passwd --stdin theadmin
echo "otus2" | sudo passwd --stdin user

# Разрешим аутентификацию по паролю
sudo bash -c "sed -i 's/^PasswordAuthentication.*$/PasswordAuthentication yes/' /etc/ssh/sshd_config && systemctl restart sshd.service"

# Добавим модуль pam_exec
sed -i '/^account    required     pam_nologin.so*/a account    required     pam_exec.so /usr/local/bin/test_login.sh' /etc/pam.d/sshd

# Скопируем и сделаем исполняемым скрипт для модуля
sudo cp /vagrant/test_login.sh /usr/local/bin/test_login.sh
sudo chmod u+x /usr/local/bin/test_login.sh


