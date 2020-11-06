#!/bin/bash

sudo su root

cp /vagrant/rsyslog_log.conf /etc/rsyslog.conf
cp /vagrant/remote.conf /etc/rsyslog.d/remote.conf
