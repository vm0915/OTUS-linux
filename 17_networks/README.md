# Архитектура сетей
[Ссылка на задание](https://github.com/erlong15/otus-linux/tree/network#%D0%BF%D1%80%D0%B0%D0%BA%D1%82%D0%B8%D1%87%D0%B5%D1%81%D0%BA%D0%B0%D1%8F-%D1%87%D0%B0%D1%81%D1%82%D1%8C)
## Планируемая архитектура
Сеть office1
- 192.168.2.0/26      - dev
- 192.168.2.64/26    - test servers
- 192.168.2.128/26  - managers
- 192.168.2.192/26  - office hardware

Сеть office2
- 192.168.1.0/25      - dev
- 192.168.1.128/26  - test servers
- 192.168.1.192/26  - office hardware


Сеть central
- 192.168.0.0/28    - directors
- 192.168.0.32/28  - office hardware
- 192.168.0.64/26  - wifi

```
Office1 ---\
      -----> Central --IRouter --> internet
Office2----/
```
Итого должны получится следующие сервера
- inetRouter
- centralRouter
- office1Router
- office2Router
- centralServer
- office1Server
- office2Server

## Теоретическая часть
Ошибок при разбиении нет.

### Свободные подсети, broadcast адрес, max узлов
Шаблон:

**Имя подсети** - комментарий
- адрес подсети/префикс --- широковещательный адрес --- максимальное количество узлов

**Office1** - свободных подсетей с префиксом /26 нет.
- 192.168.2.0/26 --- 192.168.2.63 --- 62
- 192.168.2.64/26 --- 192.168.2.127 --- 62
- 192.168.2.128/26 --- 192.168.2.191 --- 62
- 192.168.2.192/26 --- 192.168.2.255 --- 62

**Office2** - подсеть 192.168.1.128/25 была разбита на две /26
- 192.168.1.0/25 --- 192.168.1.127 --- 126
- 192.168.1.128/26 --- 192.168.1.191 --- 62
- 192.168.1.192/26 --- 192.168.1.255 --- 62

**Central** - подсеть 192.168.0.0/26 была разбита на 4 /28:
- 192.168.0.0/28 --- 192.168.0.15 --- 14
- 192.168.0.16/28 --- 192.168.0.31 --- 14
- 192.168.0.32/28 --- 192.168.0.47 --- 14
- 192.168.0.48/28 --- 192.168.0.63 --- 14

  с префиксом /26 еще 3:
- 192.168.0.64/26 --- 192.168.0.127 --- 62
- 192.168.0.128/26 --- 192.168.0.191 --- 62
- 192.168.0.192/26 --- 192.168.0.255 --- 62

## Практическая часть
[Vagrantfile](Vagrantfile) поднимает виртуалки, подключенные к разным подсетям, связанным маршрутизацией на роутерах. Все сервера могут пинговать друг друга. Выход в глобальную сеть настроен через inetRouter.


