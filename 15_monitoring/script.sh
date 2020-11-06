#!/bin/bash
sudo yum install -y wget vim && \

# Get prometheus with executable file
wget https://github.com/prometheus/prometheus/releases/download/v2.22.0/prometheus-2.22.0.linux-amd64.tar.gz && \
tar xvfz prometheus-*.tar.gz && \

# Get grafana with executable file
wget https://dl.grafana.com/oss/release/grafana-7.3.1.linux-amd64.tar.gz && \
tar -zxvf grafana-7.3.1.linux-amd64.tar.gz 

