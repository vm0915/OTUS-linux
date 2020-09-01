#!/bin/bash

sudo chown root:root /vagrant/parser.*

sudo chmod u+x /vagrant/parser.sh
sudo chmod u+x /vagrant/loggrow.sh


sudo cp /vagrant/parser.service /usr/lib/systemd/system
sudo cp /vagrant/parser.timer /usr/lib/systemd/system

sudo yum -y install mailx

sudo /vagrant/loggrow.sh &

sudo systemctl enable parser
sudo systemctl start parser

