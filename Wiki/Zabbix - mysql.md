# Pripojeni k mysql
```
mysql -u root -p zabbix
```
# Velikost dat:
```
SELECT
  TABLE_NAME,
  ROUND((DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024)
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = "zabbix"
ORDER BY (DATA_LENGTH + INDEX_LENGTH) DESC
LIMIT 10;
```
# top hosti
```
SELECT p.host, h.itemid, i.key_, count(*) AS cnt
FROM history_uint h, items i, hosts p
WHERE h.itemid = i.itemid AND i.hostid = p.hostid
GROUP BY h.itemid
ORDER BY cnt DESC;
```
# nejvic zaznamu 
```
SELECT 
	COUNT(history.itemid)
	, history.itemid
FROM history_uint AS history
GROUP BY history.itemid
ORDER BY COUNT(history.itemid) DESC
LIMIT 10;
```
# jmeno itemu podle item.id
```
SELECT i.name 
FROM items AS i
WHERE i.itemid=34206;
```
# ktereho hostu
```
SELECT 
	i.name 
	,h.host
FROM items AS i
LEFT JOIN hosts AS h ON i.hostid = h.hostid
WHERE i.itemid=37642;
```
# ukaze volne misto v tabulkach > 500MB
```
select table_name,
	round(data_length/1024/1024) as data_length_mb, 
	round(data_free/1024/1024) as data_free_mb 
from information_schema.tables 
where round(data_free/1024/1024) > 500 
order by data_free_mb;
```
# optimalizace (uvolneni) tabulky od smazanych dat
```
optimize table history_uint;
```

# Kontrola a nastaveni innodb cache size
```
SELECT @@innodb_buffer_pool_size/1024/1024/1024;
```
## nastaveni velikosti cache v MySQL
```
nano /etc/mysql/mysql.conf.d/mysqld.cnf
```
```
innodb_buffer_pool_size=4G
```
```
