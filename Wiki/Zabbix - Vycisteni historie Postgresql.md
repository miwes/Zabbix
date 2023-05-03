# prejmenuj stavajici tabulku
```
ALTER TABLE history_uin RENAME TO history_uint_old;
ALTER TABLE history RENAME TO history_old;
ALTER TABLE history_str RENAME TO history_str_old;
ALTER TABLE history_text RENAME TO history_text_old;
```

# zaloz novou https://git.zabbix.com/projects/ZBX/repos/zabbix/browse/database/postgresql/history_pk_prepare.sql?at=refs%2Ftags%2F6.0.0
```
CREATE TABLE history_uint (
	itemid                   bigint                                    NOT NULL,
	clock                    integer         DEFAULT '0'               NOT NULL,
	value                    numeric(20)     DEFAULT '0'               NOT NULL,
	ns                       integer         DEFAULT '0'               NOT NULL,
	PRIMARY KEY (itemid,clock,ns)
);
```

# prekopiruj data od clock > epoch time
```
INSERT INTO history_uint SELECT * FROM history_uint_old WHERE clock > '1679312723' ON CONFLICT DO NOTHING;
INSERT INTO history SELECT * FROM history_old WHERE clock > '1679312723' ON CONFLICT DO NOTHING;
INSERT INTO history_str SELECT * FROM history_str_old WHERE clock > '1679312723' ON CONFLICT DO NOTHING;
INSERT INTO history_text SELECT * FROM history_text_old WHERE clock > '1679312723' ON CONFLICT DO NOTHING;
```

# pridani prav
```
ALTER TABLE history_uint OWNER TO zabbix; 
ALTER TABLE history OWNER TO zabbix; 
ALTER TABLE history_str OWNER TO zabbix;
ALTER TABLE history_text OWNER TO zabbix;
```

# smaz starou tabulku
```
DROP TABLE history_uint_old;
DROP TABLE history_old;
DROP TABLE history_str_old;
DROP TABLE history_text_old;
```



SELECT COUNT(*) FROM history_uint_new;

ALTER TABLE history_uint RENAME TO history_uint_old2;
ALTER TABLE history_uint_new RENAME TO history_uint;


INSERT INTO history_uint SELECT * FROM history_uint_old2 ON CONFLICT (itemid,clock,ns) DO NOTHING;

DROP TABLE history_uint_old;
DROP TABLE history_uint_old2;

# vypis indexy
select *
from pg_indexes
where tablename = 'history';

