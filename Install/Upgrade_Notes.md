# Upgrade Zabbix 5 to 6

## Upgrade DB
- https://mariadb.com/docs/server/service-management/upgrades/community-server/release-series-cs10-6/
- Stop Zabbix server
```
/etc/init.d/zabbix-server stop
```

- check version DB
```
apt-cache show mariadb-server | grep Version
```

- backup DB
	When missing command - apt install mariadb-backup
```
sudo mariabackup  --backup \
      --user=root \
      --password= \
      --target-dir=/home/adminzbx/mariabackup/preupgrade_backup
	  
sudo mariabackup --prepare \
      --target-dir=/home/adminzbx/mariabackup/preupgrade_backup
```

- Upgrade for Ubuntu 20
```
sudo systemctl status mariadb
sudo systemctl stop mariadb

sudo apt remove mariadb-* galera-3

sudo apt install -y software-properties-common
sudo apt-key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc'
sudo apt update && sudo apt install -y mariadb-server mariadb-client

sudo systemctl start mariadb
sudo systemctl enable mariadb
```

