# Ansible
**Домашнее задание:**
```
Первые шаги с Ansible
Подготовить стенд на Vagrant как минимум с одним сервером. На этом сервере используя Ansible необходимо развернуть nginx со следующими условиями:
- необходимо использовать модуль yum/apt
- конфигурационные файлы должны быть взяты из шаблона jinja2 с перемененными
- после установки nginx должен быть в режиме enabled в systemd
- должен быть использован notify для старта nginx после установки
- сайт должен слушать на нестандартном порту - 8080, для этого использовать переменные в Ansible

Домашнее задание считается принятым, если:
- предоставлен Vagrantfile и готовый playbook/роль ( инструкция по запуску стенда, если посчитаете необходимым )
- после запуска стенда nginx доступен на порту 8080
- при написании playbook/роли соблюдены перечисленные в задании условия
```

**Ход выполнения:**

## Vagrantfile
Для запуска стенда необходимо 4 Гб ОЗУ

`vagrant up` поднимает сервер с ansible и две машины для управления.

В `Vagrantfile` особый провиженинг сервера ansible обеспечен с помощью условия:
```ruby
if  boxname.to_s.eql? "ansible"
	    box.vm.synced_folder "vagrant", "/vagrant", type: "rsync"
            box.vm.provider :virtualbox do |vb|
                vb.customize ["modifyvm", :id, "--memory", "3072"] 
	    end
	    box.vm.provision "file", source: ".vagrant/machines/machine1/virtualbox/private_key", destination: "/vagrant/mkey1"
	    box.vm.provision "file", source: ".vagrant/machines/machine2/virtualbox/private_key", destination: "/vagrant/mkey2"
	    box.vm.provision "shell", inline: <<-SHELL
    sudo yum install -y epel-release
		sudo yum install -y ansible
		cd /vagrant
		ansible-playbook playbook1.yml
		ansible-playbook playbook2.yml
		curl -I 192.168.11.101:8080
		curl -I 192.168.11.102:80
		SHELL
end

```
Здесь `box.vm.synced_folder "vagrant", "/vagrant", type: "rsync"` - копирует заготовленные файлы плейбуков, роли, [конфига ансибла](vagrant/ansible.cfg), и [инвентори файла](vagrant/hosts.txt)

Для авторизации ansible на подчиненных машинах было решено использовать сгенерированные vagrant'ом ключи. Для этого мы их копируем в машину с ансиблом в ходе провижионинга: 

`box.vm.provision "file", source: ".vagrant/machines/machine1/virtualbox/private_key", destination: "/vagrant/mkey1"` 

Затем устанавливаем необходимое ПО:
```ruby
sudo yum install -y epel-release
sudo yum install -y ansible
```

Для полной автоматизации процесса далее выполняются [playbook1](vagrant/playbook1.yml), который пингует машины и [playbook2](vagrant/playbook2.yml) устанавливает и конфигурирует nginx на разных портах для каждой машины.
```ruby
ansible-playbook playbook1.yml
ansible-playbook playbook2.yml
```

В конце проверяем что все успешно запустилось и работает, для этого делаем запрос заголовков на определенных портах для каждой машины:
```ruby
curl -I 192.168.11.101:8080
curl -I 192.168.11.102:80
```
## Playbook
Для начала в [инвентори-файле](vagrant/hosts.txt) указали специфичные для каждой машины параметры: ip-адрес, рабочий порт nginx, путь до ключа ssh.

В [playbook2](vagrant/playbook2.yml) указываем имя, исполение sudo (`become: yes`) и роль.

Скелет под роль был создан `ansible-galaxy`

В нем мы дополнили каталоги:
- [vars](vagrant/roles/deploy_nginx/vars/main.yml)
```yaml
# vars file for deploy_nginx
ansible_user      : vagrant
nginx_config_path : /etc/nginx
```
- [templates](vagrant/roles/deploy_nginx/templates/main.yml) с шаблоном конфига nginx

- [tasks](vagrant/roles/deploy_nginx/tasks/main.yml) 
```yaml
# tasks file for deploy_nginx
- name: Install epel-release
  yum: name=epel-release state=latest

- name: Install Nginx Web Server
  yum: name=nginx state=latest
  notify:
    - Start Nginx

- name: Copy config file
  template: src=nginx.j2 dest={{ nginx_config_path }}/nginx.conf mode=0644
  notify:
    - Reload Nginx

- name: Enable Nginx
  service: name=nginx enabled=yes
```
- [handlers](vagrant/roles/deploy_nginx/handlers/main.yml)
```yaml
# handlers file for deploy_nginx
- name: Reload Nginx
  service: name=nginx state=reloaded

- name: Start Nginx
  service: name=nginx state=started
```

