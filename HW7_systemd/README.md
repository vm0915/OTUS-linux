# Systemd 

## 1. �������� service
������ ������� ����������� � �������� �������, ������� ��������� ���� �� ������� ��������� ����� � �������� �� ���� ����� systemd.
��� ����� ��� ������� ������ [monitoring.sh](monitoring/monitoring.sh) ������������� ����� "yes" � [file](monitoring/file]
� **/etc/systemd/system/** ��� �������� ���� ����� [monitoring.service](monitoring/monitoring.service) � ���� ������� [monitoring.timer](monitoring/monitoring.timer), ����������� ������ ������ 30 ������.
�������� ������� ���� ��������� �� 1 ������� (������ 30 ��� �� ���������).
��������� �������� ������ ����������������� � [�������](script.sh)

## 2. ���������� init-������ �� unit-����
������������� �������������� ����������� � spawn-fcgi � httpd ��� ����������� �������
```bash
sudo yum install -y epel-release
sudo yum install -y php-cgi mod_fcgid httpd spawn-fcgi
```
������ ��������� � **/etc/sysconfig/spawn-fcgi**
�������� ������������� [���� �������](spawn-fcgi.service)
```bash
[Unit]
Description=Spawn-Fcgi service

[Service]
Type=simple
EnvironmentFile=/etc/sysconfig/spawn-fcgi
ExecStart=/usr/bin/spawn-fcgi -n $OPTIONS

[Install]
WantedBy=multi-user.target
```
������������ ������������, �������� � ������������ � �������� ������
```bash
sudo systemctl daemon-reload
sudo systemctl enable spawn-fcgi.service
sudo systemctl start spawn-fcgi
```

## 3. ��������� unit-���� httpd ������������ �������� ���������
��� ����� � **/usr/lib/systemd/system/** ������� ���� ������� *httpd@.service* � ��������� *httpd@1.service* *httpd@2.service*
�������� � ������ ��������� ����� ������������ � ��������
������� */etc/httpd/conf/* ����� **httpd@1.conf** � **httpd@2.conf**
��������� � ��� ��������� **PidFile** � **Listen**
������ ������� ��� ��������� SELinux � ���������� ������������� ������������� ������ ��� httpd
```bash
sudo yum install -y policycoreutils-python
sudo semanage port -a -t http_port_t -p tcp 7777
sudo semanage port -a -t http_port_t -p tcp 8888
```
������������ ������������, �������� � ������������ � �������� ����������
