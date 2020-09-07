# Package management

## Создание своего RPM-пакета 

RPM-пакет будем собирать из [исходников](https://github.com/thedolphin/clogtail) предоставленных преподавателем.

Необходимое ПО: `createrepo`, `rpmdevtools`.

Инструкции для `rpmbuild` по сборке пакета содержит SPEC-файл.
Он делится на *Preamble* и *Body*.

В нашем примере *Preamble* содержит имя, версию, необходимое для билда ПО и др.:
```bash
Name:           clogtail
Version:        0.3.0
Release:        2%{?dist}
Summary:        log follower for periodic jobs
Group:          Applications/File
License:        BSD
BuildRequires:  git gcc
```
В *Body* содержатся следующие *items*:

- Описание:
```bash
%description
Log follower for periodic jobs
```

- Подготовка содежит встроенный макрос `%setup`, который распаковывает исходные тексты и делает в директорию исходных текстов `cd`. В нашем примере исходные тексты скачиваются с github:
```bash
%prep
%setup -c -T
curl -fL https://api.github.com/repos/thedolphin/clogtail/tarball/master |
tar -xzvf - --strip 1
```

- В итеме `%build` вызывается команда `make`, которая в свою очередь читает **Makefile**: 
```bash
%build
make
```

**Makefile**:
```bash
all: clogtail

clogtail: clogtail.c
	gcc -g -Wall -o clogtail clogtail.c

clean:
	rm -f clogtail
```

- В итеме `%install` содержится макрос `%{__install}` (значение которого можно узнать в /usr/lib/rpm/macros). Здесь он только вызывает /usr/bin/install:
```bash
%install
%{__install} -D -m0755 clogtail ${RPM_BUILD_ROOT}/usr/bin/clogtail
```
`-D` - создает все родительские каталоги
`-m0755` - устанавливает права rwxr-xr-x на устанавливаемый файл
`${RPM_BUILD_ROOT}` - здесь ~/rpmbuild/BUILDROOT

- В итеме `%clean` команды вычищают файлы, созданные на других стадиях
```bash
%clean
rm -rf $RPM_BUILD_ROOT
```

- В итеме `%files` задают списки файлов и каталогов, которые с соответствующими атрибутами должны быть скопированы из дерева сборки в rpm-пакет и затем будут копироваться в целевую систему при установке этого пакета:
```bash
%files
/usr/bin/clogtail
```

Установим необходимое для сборки ПО:
```bash
yum-builddep /vagrant/clogtail/clogtail.spec -y
```

Соберем пакет командой `rpmbuild -bb`.
`-bb` - Build a binary package (after doing the %prep, %build, and %install stages).

## Установка и настройка своего репозитория

Доступ к репозиторию будет осуществляться через `nginx`.
Пакеты будут располагаться в */usr/share/nginx/html/repo*

Создадим репозиторий (по сути добавляем метадату в rpm хранилище) командой `createrepo /usr/share/nginx/html/repo/`
Ее необходимо запускать каждый раз при изменении содержимого репозитория.

Добавим в *location /* `/etc/nginx/nginx.conf`
```bash
location / {
root /usr/share/nginx/html;
index index.html index.htm;
autoindex on; 
}
```

Проверим синтаксис и перечитаем конфиг:
```bash
nginx -t
nginx -s reload
```

Затем добавляем свой репозиторий в yum:
```bash
cat >> /etc/yum.repos.d/otus.repo << EOF
[otus]
name=otus-linux
baseurl=http://localhost/repo
gpgcheck=0
enabled=1
EOF
```

Проверяем и устанавливаем из него clogtail:
```bash
yum repolist enabled | grep otus
yum install clogtail -y
type clogtail
```


