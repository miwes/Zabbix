#!/bin/bash

# stahnuti posledniho configurace pro Zabbix agenta
echo Stahovani ac.conf z Githubu
wget -O /etc/zabbix/zabbix_agentd.d/ac.conf https://raw.githubusercontent.com/miwes/Zabbix/master/Config/Linux/ac.conf

echo Restart agenta
systemctl restart zabbix-agent
