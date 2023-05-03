USE zabbix;
# create new empty zabbix tables
CREATE TABLE history_new LIKE history;
CREATE TABLE history_uint_new LIKE history_uint;
CREATE TABLE history_str_new LIKE history_str;
CREATE TABLE history_log_new LIKE history_log;
CREATE TABLE history_text_new LIKE history_text;
CREATE TABLE alerts_new LIKE alerts;
CREATE TABLE trends_new LIKE trends;
CREATE TABLE trends_uint_new LIKE trends_uint;
# drop old zabbix tables (this frees disk space)
DROP TABLE history;
DROP TABLE history_uint;
DROP TABLE history_str;
DROP TABLE history_log;
DROP TABLE history_text;
DROP TABLE alerts;
DROP TABLE trends;
DROP TABLE trends_uint;
# rename new tables to old name
ALTER TABLE history_new RENAME history;
ALTER TABLE history_uint_new RENAME history_uint;
ALTER TABLE history_str_new RENAME history_str;
ALTER TABLE history_log_new RENAME history_log;
ALTER TABLE history_text_new RENAME history_text;
ALTER TABLE alerts_new RENAME alerts;
ALTER TABLE trends_new RENAME trends;
ALTER TABLE trends_uint_new RENAME trends_uint;
#
EXIT
