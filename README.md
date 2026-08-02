Описание проекта

Домашнее задание №6 урока 12 по курсу Инфраструктура высоконагруженных систем от OTUS. 
Цель работы: 
- развернуть отказоустойчивый кластер PostgreSQL;
- обеспечить автоматическое управление лидерством и высокую доступность с помощью Patroni;
- настроить сервис-дискавери через etcd/Consul/ZooKeeper и балансировку с HAProxy или PgBouncer..

Описание/Пошаговая инструкция выполнения домашнего задания:

Используем terraform и ansible роль для развертывания отказоустойчивого кластера PostgreSQL. 

    Разворачиваем отказоустойчивый кластер PostgreSQL на ВМ в Proxmox.
    Создаем внутри кластера БД для проекта.

Подготовленная инфраструктура

В лабораторной работе развернуты 2 nginx с балансировкой через VIP Keepalived + 2 backend + 3 ВМ БД PostgreSQL

    nginx-1 — первый nginx-хост;
    nginx-2 — второй nginx-хост;
    backend-1 — первый backend-хост с Django-приложением;
    backend-2 — второй backend-хост с Django-приложением;
    db-1, db-2, db-3 — три узла PostgreSQL (Patroni, etcd).

Компоненты кластера PostgreSQL

    PostgreSQL 16 — основная СУБД.
    Patroni — управление кластером, автоматический выбор лидера (failover) и восстановление.
    etcd 3.4 (3 узла, на db-1..db-3) — распределённое хранилище состояния (DCS) для Patroni.
    HAProxy (на backend-1, backend-2) — балансировщик с разделением трафика:
        Порт 5432 — write (только текущий лидер, проверка /master).
        Порт 5433 — read (все реплики, round-robin, проверка /replica).

1. Развёртывание etcd с помошью роли etcd
 - Установка etcd через snap (так как в Ubuntu 24.04 пакет отсутствует в репозиториях).
 - Конфигурация в формате YAML (/var/snap/etcd/common/etcd.conf.yml) с включённым API v2 (enable-v2: true) для совместимости с Patroni.
 - Запуск сервиса snap.etcd.etcd и формирование кластера из трёх узлов.
2. Установка PostgreSQL и Patroni (роль postgresql)
 - Установка PostgreSQL, 
 - Установка Patroni и зависимостей
 - Настройка Patroni (/etc/patroni/patroni.yml) 
 - Запуск Patroni как systemd-сервиса.
3. Настройка HAProxy (роль haproxy)
 - Установка HAProxy.
 - Конфигурация /etc/haproxy/haproxy.cfg с двумя фронтендами:
    postgres_write (порт 5432) → бэкенд postgres_primary (проверка /master через Patroni API).
    postgres_read (порт 5433) → бэкенд postgres_replicas (проверка /replica).
 - Запуск HAProxy.
4. Развертывание frontend 
5. Развёртывание Django-приложения (роль backend_app)
    

На скриншоте 1 видим что кластер etcd создан, готов к работе + вывод состояния Pareoni на мастер ноде, также видно состав кластера 
![screen01](screenshots/screen01.png)

На скриншотах 2 и 3 видим состояние patroni с replica нод
![screen02](screenshots/screen02.png)
![screen03](screenshots/screen03.png)

На скриншоте 4 видим логи переключения мастера после отключения db-1, видно как роль мастера на себя взяла нода db-3, в после включения db-1 она вернулась в кластер в качестве replica
![screen04](screenshots/screen04.png)

На скриншоте 5 видим что db-3 стала лидером
![screen05](screenshots/screen05.png)

На скриншоте 6 видим страницу статистики HAProxy. На ней видны все серверы PostgreSQL в статусе UP, а также разделение трафика на write (порт 5432) и read (порт 5433).
![screen06](screenshots/screen06.png)

