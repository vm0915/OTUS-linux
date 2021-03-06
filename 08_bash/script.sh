#!/bin/bash

sudo chown root:root /vagrant/parser.*

sudo chmod u+x /vagrant/parser.sh
sudo chmod u+x /vagrant/loggrow.sh


sudo cp /vagrant/parser.service /usr/lib/systemd/system
sudo cp /vagrant/parser.timer /usr/lib/systemd/system

sudo yum -y install mailx

sudo /vagrant/loggrow.sh &

sudo systemctl daemon-reload
sudo systemctl enable parser
sudo systemctl enable parser.timer
sudo systemctl start parser.service

