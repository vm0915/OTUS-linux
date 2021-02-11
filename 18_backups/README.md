# Резервное копирование
**Домашнее задание:**
```
Настраиваем бэкапы
Настроить стенд Vagrant с двумя виртуальными машинами: backup_server и client

Настроить удаленный бекап каталога /etc c сервера client при помощи borgbackup. Резервные копии должны соответствовать 
следующим критериям:

- Директория для резервных копий /var/backup. Это должна быть отдельная точка монтирования. В данном случае 
для демонстрации размер не принципиален, достаточно будет и 2GB.
- Репозиторий дле резервных копий должен быть зашифрован ключом или паролем - на ваше усмотрение
- Имя бекапа должно содержать информацию о времени снятия бекапа
- Глубина бекапа должна быть год, хранить можно по последней копии на конец месяца, кроме последних трех. 
Последние три месяца должны содержать копии на каждый день. 
Т.е. должна быть правильно настроена политика удаления старых бэкапов
- Резервная копия снимается каждые 5 минут. Такой частый запуск в целях демонстрации.
- Написан скрипт для снятия резервных копий. Скрипт запускается из соответствующей Cron джобы, 
либо systemd timer-а - на ваше усмотрение.
- Настроено логирование процесса бекапа. Для упрощения можно весь вывод перенаправлять в logger с соответствующим тегом. 
Если настроите не в syslog, то обязательна ротация логов

Запустите стенд на 30 минут. Убедитесь что резервные копии снимаются. 
Остановите бекап, удалите (или переместите) директорию /etc и восстановите ее из бекапа. 
Для сдачи домашнего задания ожидаем настроенные стенд, логи процесса бэкапа и описание процесса восстановления.
```
**Ход выполнения:**

`Vagrantfile` содержит описание двух машин: server (с дополнительным диском), на котором хранятся бекапы и client, у которого с `/etc` снимается резервная копия.

Для снятия резервной копии используется **Borgbackup**.

## Server
На сервере устанавливается borgbackup из epel-release.

На отдельном диске создается файловая система и монтируется в `/var/backup`:
```bash
sudo mkfs.xfs /dev/sdb
sudo mount /dev/sdb /var/backup
```
Инициализируется репозиторий для бекапов:
```bash
BORG_PASSPHRASE="otus" borg init --encryption=repokey /var/backup
```
`BORG_PASSPHRASE` - содержит пароль запрашиваемый при инициализации.

## Client
На клиенте устанавливается borgbackup из epel-release.

Вагрант копирует на машину [script.sh](script.sh) и ключи, сгенерированные при поднятии виртуалки. Они будут использоваться для ssh соединения, поверх которого работает borg. 

Также при провижиненге создается запись в `cron.d` для бекапов каждые 5 минут:
```bash
sudo echo "*/5 * * * * root /home/vagrant/script.sh" > /etc/cron.d/borg-backup 
```

В [script.sh](script.sh) интересны следующие переменные:
```bash
...
BORG_PASSPHRASE="otus" \
BORG_RSH="ssh -o 'StrictHostKeyChecking=no' -i /home/vagrant/private_key" \
borg create -v --stats $REPOSITORY::'{now:%Y-%m-%d-%H-%M}' /etc \
2>&1 | logger &
...
```
`BORG_PASSPHRASE="otus"` - пароль

`BORG_RSH="ssh -o 'StrictHostKeyChecking=no' -i /home/vagrant/private_key"` - переменные для ssh подключения, убираем проверку fingerprint и указываем путь к ключу.


Вывод borg перенаправляется в logger, `/var/log/messages`. Пример вывода:
```bash
Nov 19 08:20:04 localhost root: Creating archive at "root@192.168.11.10:/var/backup/::{now:%Y-%m-%d-%H-%M}"
Nov 19 08:20:05 localhost root: ------------------------------------------------------------------------------
Nov 19 08:20:05 localhost root: Archive name: 2020-11-19-08-20
Nov 19 08:20:05 localhost root: Archive fingerprint: 3b18747cf412d6b542aa693a44340acaac95458c12fd8033dc1cda7f985e35c5
Nov 19 08:20:05 localhost root: Time (start): Thu, 2020-11-19 08:20:04
Nov 19 08:20:05 localhost root: Time (end):   Thu, 2020-11-19 08:20:04
Nov 19 08:20:05 localhost root: Duration: 0.85 seconds
Nov 19 08:20:05 localhost root: Number of files: 1699
Nov 19 08:20:05 localhost root: Utilization of max. archive size: 0%
Nov 19 08:20:05 localhost root: ------------------------------------------------------------------------------
Nov 19 08:20:05 localhost root:                       Original size      Compressed size    Deduplicated size
Nov 19 08:20:05 localhost root: This archive:               28.43 MB             13.49 MB                674 B
Nov 19 08:20:05 localhost root: All archives:               56.85 MB             26.99 MB             11.84 MB
Nov 19 08:20:05 localhost root: 
Nov 19 08:20:05 localhost root:                       Unique chunks         Total chunks
Nov 19 08:20:05 localhost root: Chunk index:                    1282                 3394
Nov 19 08:20:05 localhost root: ------------------------------------------------------------------------------
```

Контроль удаления бекапов происходит с помощью:
```bash
BORG_PASSPHRASE="otus" \
BORG_RSH="ssh -o 'StrictHostKeyChecking=no' -i /home/vagrant/private_key" \
borg prune -v --show-rc --list $REPOSITORY \
 --keep-daily=90 --keep-monthly=9
 ```
 `--keep-daily=90` - хранит по ежедневному бекапу последние 3 месяца
 
 `--keep-monthly=9` - хранит по одному бекапу на месяц, в период до тех 3 месяцев что указаны выше. В итоге получаем бекапы длиной в год.
 
 
 
 ## Восстановление из бекапа
 Посмотрим существующие бекапы:
 ```backup
[root@client ~]# BORG_PASSPHRASE="otus" \
BORG_RSH="ssh -o 'StrictHostKeyChecking=no' -i /home/vagrant/private_key" \
borg list ssh://root@192.168.11.10:22/var/backup
2020-11-19-08-30                     Thu, 2020-11-19 08:30:03 [f3df9f9d9abfd0d098fb0711ee9fd9d7de1c56036029f3a7596fd4795858ae4c]
```
Извлекам бекап в текущую директорию:
```
BORG_PASSPHRASE="otus" \
BORG_RSH="ssh -o 'StrictHostKeyChecking=no' -i /home/vagrant/private_key" \
borg extract ssh://root@192.168.11.10/var/backup::2020-11-19-08-30
```
