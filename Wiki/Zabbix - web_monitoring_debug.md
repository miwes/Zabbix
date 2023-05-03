- zapnuti logovani
  - prvni spusteni zvedne log level na 3
  - druhe spusteni zvedne log level na 5
```
zabbix_server --runtime-control log_level_increase="http poller"
zabbix_server --runtime-control log_level_increase="http poller"
```

- vypnuti logovani
```
zabbix_server --runtime-control log_level_decrease="http poller"
zabbix_server --runtime-control log_level_decrease="http poller"
```
  
