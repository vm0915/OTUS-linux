# Systemd 
**Домашнее задание:**
```
Выполнить следующие задания и подготовить развёртывание результата выполнения
с использованием Vagrant и Vagrant shell provisioner (или Ansible, на Ваше усмотрение):
1. Написать service, который будет раз в 30 секунд мониторить лог 
на предмет наличия ключевого слова (файл лога и ключевое слово должны задаваться в /etc/sysconfig);
2. Из репозитория epel установить spawn-fcgi и переписать init-скрипт на unit-файл 
(имя service должно называться так же: spawn-fcgi);
3. Дополнить unit-файл httpd (он же apache) возможностью запустить несколько инстансов сервера 
с разными конфигурационными файлами;
4*. Скачать демо-версию Atlassian Jira и переписать основной скрипт запуска на unit-файл.
```

**Ход выполнения:**

## 1. Написать service
Первое задание заключалось в написани скрипта, который мониторит файл на наличие ключевого слова и создания из него юнита systemd.
Для этого был написан скрипт [monitoring.sh](monitoring/monitoring.sh) отслеживающий слово "yes" в [file](monitoring/file)
В **/etc/systemd/system/** был размещен файл юнита [monitoring.service](monitoring/monitoring.service) и файл таймера [monitoring.timer](monitoring/monitoring.timer), запускающий сервис каждые 30 секунд.
Точность таймера была увеличена до 1 секунды (вместо 30 сек по умолчанию).
Подробное описание команд закомментированно в [скрипте](script.sh)

## 2. Переписать init-скрипт на unit-файл
Устанавливаем дополнительный репозиторий и spawn-fcgi с httpd для нормального запуска
```bash
sudo yum install -y epel-release
sudo yum install -y php-cgi mod_fcgid httpd spawn-fcgi
```
Правим параметры в **/etc/sysconfig/spawn-fcgi**
Копируем заготовленный [файл сервиса](spawn-fcgi.service)
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
Перечитываем конфигурацию, включаем в автозагрузку и стартуем сервис
```bash
sudo systemctl daemon-reload
sudo systemctl enable spawn-fcgi.service
sudo systemctl start spawn-fcgi
```

## 3. Дополнить unit-файл httpd возможностью создания инстансов
Для этого в **/usr/lib/systemd/system/** создаем файл шаблона *httpd@.service* и инстансов *httpd@1.service* *httpd@2.service*
Изменяем в файлах инстансов файлы конфигурации и описания
Создаем */etc/httpd/conf/* файлы **httpd@1.conf** и **httpd@2.conf**
Указываем в них переменую **PidFile** и **Listen**
Ставим утилиты для настройки SELinux и разрешения прослушивания нестандартных портов для httpd
```bash
sudo yum install -y policycoreutils-python
sudo semanage port -a -t http_port_t -p tcp 7777
sudo semanage port -a -t http_port_t -p tcp 8888
```
Перечитываем конфигурацию, включаем в автозагрузку и стартуем экземпляры
