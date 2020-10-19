#!/bin/bash
mkdir /home/vagrant/coretest
cd /home/vagrant/coretest

sudo yum update -y && \
sudo yum install -y wget flex bison bc openssl-devel gcc libelf-devel elfutils-libelf-devel perl 

wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.6.10.tar.xz
DISTRO='linux-5.6.10'
export $DISTRO
tar xf $DISTRO.tar.xz
cd /home/vagrant/coretest/$DISTRO

sudo cp /boot/config-$(uname -r) .config
sudo make olddefconfig && \
sudo make -j16 && \
sudo make -j16 O=$BUILD modules && \
sudo make O=$BUILD modules_install && sudo make O=$BUILD install

sudo rm -f /boot/*3.10*
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
sudo grub2-set-default 0
sudo sudo shutdown -r now

cd /home/vagrant
wget https://download.virtualbox.org/virtualbox/6.1.6/VBoxGuestAdditions_6.1.6.iso
sudo mount /home/vagrant/VBoxGuestAdditions_6.1.6.iso /media -o loop
cd /media
sudo ./VBoxLinuxAdditions.run


