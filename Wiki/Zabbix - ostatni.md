Najdi ve vsech souborech string
-------------------------------
grep -r "Mar 14 01:0[5-9]*" .

Totalni zabiti procesu
------------------------
killall zabbix_server -s SIGKILL

Rucni spusteni Housekeeperu
----------------------------
zabbix_server -c /etc/zabbix/zabbix_server.conf -R housekeeper_execute
 

Velikost adresare
------------------
du -sh /var/*

Zvednuti a snizeni log levelu za behu
--------------------------------------
zabbix_server -Rlog_level_increase="vmware collector"
zabbix_server -Rlog_level_decrease="vmware collector"


Seznam procesu pooleru (jejich stav)
------------------------------------
ps aux | grep zabbix_server

watch -n 0.2 ps -fu zabbix

watch -tn 0.2 'ps -fC zabbix_server | grep history'

watch -tn 0.2 'ps -fC zabbix_server | grep poller'


Pustit jako zabbix identita pro otestovani
------------------------------------------
sudo -u zabbix bash
cd /var/log/
less messages
