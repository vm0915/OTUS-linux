FROM centos:centos7

WORKDIR /opt
RUN yum install -y wget \
    && wget https://github.com/prometheus/prometheus/releases/download/v2.22.0/prometheus-2.22.0.linux-amd64.tar.gz \
    && tar xvfz prometheus-2.22.0.linux-amd64.tar.gz \
    && cd prometheus-2.22.0.linux-amd64 
COPY prometheus.yml /opt/prometheus-2.22.0.linux-amd64
EXPOSE 9090
CMD ["./prometheus"]
