#### Build image
`docker build  -t gershon-proxysql .`
#### Run
export MYPATH=C:\\Users\\GershonA\\Documents\\Project\\proxysql
```
docker run -d --name=cluster3_proxysql3 \
-v "$MYPATH/config/secrets.env":/proxysql/secrets/secrets.env \
-v "$MYPATH/config/proxysql.cnf.tpl":/proxysql/conf/proxysql.cnf.tpl \
-p 16032:6032 \
-p 16033:6033 \
-p 16080:6080 \
gershon-proxysql
```

`docker run -d --name=cluster3_proxysql3 -v "$MYPATH/config/secrets.env":/proxysql/secrets/secrets.env -v "$MYPATH/config/proxysql.cnf.tpl":/proxysql/conf/proxysql.cnf.tpl -p 16032:6032 -p 16033:6033 -p 16080:6080 gershon-proxysql`

#### Run with variables
```
docker run -d --name=cluster3_proxysql3 \
-v "$MYPATH/config/secrets.env":/proxysql/secrets/secrets.env \
-v "$MYPATH/config/proxysql.cnf.tpl":/proxysql/conf/proxysql.cnf.tpl \
-e PROXYSQL_CONF_CHECK_INTERVAL=15 \
-e PROXYSQL_CONF_LIVE_RELOAD=true \
-e PROXYSQL_ADMIN_USERNAME=admin \
-e PROXYSQL_ADMIN_PASSWORD=admin \
-e PROXYSQL_ADMIN_HOST=0.0.0.0 \
-e PROXYSQL_ADMIN_PORT=6032 \
-e PROXYSQL_MYSQL_THREADS=6 \
-p 16032:6032 \
-p 16033:6033 \
-p 16080:6080 \
--net=pxc-network \
gershon-proxysql
```
- If percona cluster running on own network, add ` --net=[NETWORk NAME]` 
#### Enter Admin interface
- To connect remotely , use exposed port 16032
`docker exec -it cluster3_proxysql3 bash`
`mysql -h127.0.0.1 -P6032 -uadmin -padmin --prompt "ProxySQL Admin>"`
#### Login as client 
- To connect remotely , use exposed port 16033
`mysql -u proxysql -pProxySQLPa55 -h 127.0.0.1 -P 16033 --prompt='ProxySQLClient> '`
P.S "proxysql" user should be added to percona cluster as well
```
mysql@pxc2> CREATE USER 'proxysql'@'%' IDENTIFIED BY 'ProxySQLPa55';
mysql@pxc2> GRANT USAGE ON *.* TO 'proxysql'@'%';
```
- To ensure that monitoring is enabled, check the monitoring logs:
 SELECT * FROM monitor.mysql_server_connect_log ORDER BY time_start_us DESC LIMIT 6;
 SELECT * FROM monitor.mysql_server_ping_log ORDER BY time_start_us DESC LIMIT 6;
 ```
 ProxySQL Admin>SELECT * FROM monitor.mysql_server_connect_log ORDER BY time_start_us DESC LIMIT 6;
+------------+------+------------------+-------------------------+------------------------------------------------------------------------------------------+
| hostname   | port | time_start_us    | connect_success_time_us | connect_error                                                                            |
+------------+------+------------------+-------------------------+------------------------------------------------------------------------------------------+
| 172.18.0.4 | 3306 | 1608203290317542 | 1699                    | NULL                                                                                     |
| 172.18.0.5 | 3306 | 1608203290304804 | 2312                    | NULL                                                                                     |
```
#### Check if hosts defined in secret.env was loaded successfully and online
`docker exec -it  cluster3_proxysql3 mysql -h127.0.0.1 -P6032 -uadmin -padmin -e  "SELECT * FROM mysql_servers;"`
```
ProxySQL Admin>SELECT * FROM mysql_servers;
+--------------+------------+------+-----------+--------+--------+-------------+-----------------+---------------------+---------+----------------+---------+
| hostgroup_id | hostname   | port | gtid_port | status | weight | compression | max_connections | max_replication_lag | use_ssl | max_latency_ms | comment |
+--------------+------------+------+-----------+--------+--------+-------------+-----------------+---------------------+---------+----------------+---------+
| 0            | 172.18.0.3 | 3306 | 0         | ONLINE | 1      | 0           | 5               | 0                   | 0       | 0              |         |
| 0            | 172.18.0.4 | 3306 | 0         | ONLINE | 1      | 0           | 10              | 0                   | 0       | 0              |         |
| 0            | 172.18.0.5 | 3306 | 0         | ONLINE | 1      | 0           | 10              | 0                   | 0       | 0              |         |
+--------------+------------+------+-----------+--------+--------+-------------+-----------------+---------------------+---------+----------------+---------+
```
#### Testing
1. Import example database `thegeekstuff` to percona cluster
`test\thegeekstuff.sql`
2. Create MySQL User on percona cluster
```
CREATE USER 'playgrounduser'@'%' IDENTIFIED BY 'playgroundpassword';
GRANT ALL PRIVILEGES on thegeekstuff.* to 'playgrounduser'@'%';
FLUSH PRIVILEGES;
```
3. Create user in proxysql:
```
INSERT INTO mysql_users(username, password, default_hostgroup) VALUES ('playgrounduser', 'playgroundpassword', 2);
LOAD MYSQL USERS TO RUNTIME;
SAVE MYSQL USERS TO DISK;
```
4. Login with created user
```
mysql -u playgrounduser -pplaygroundpassword -h 127.0.0.1 -P 16033 --prompt='ProxySQLClient> '
```
### Benchmark
1. Percona
- create database sysbench
`mysql> create database sysbench;`
- Verify user sbuser with password sbpass exists 
```
mysql@p> CREATE USER 'sbuser'@'%' IDENTIFIED BY 'sbpass';
Query OK, 0 rows affected (0.01 sec)

mysql@> GRANT ALL ON *.* TO 'sbuser'@'%';
Query OK, 0 rows affected (0.00 sec)
mysql@>FLUSH PRIVILEGES;
```
- Prepare
```
sysbench /usr/share/sysbench/oltp_read_write.lua \ 
--tables=5 \
--table-size=200000 \
--num-threads=1 \
--rand-type=uniform \
--db-driver=mysql \
--mysql-db=sysbench \
--mysql-user=sbuser \
--mysql_password=sbpass \
--mysql-host=127.0.0.1 \
--mysql-port=3306  \
prepare 
```
One liner
```
sysbench /usr/share/sysbench/oltp_read_write.lua --tables=5 --table-size=200000 --num-threads=1 --rand-type=uniform --db-driver=mysql --mysql-db=sysbench --mysql-user=sbuser --mysql_password=sbpass --mysql-host=127.0.0.1 --mysql-port=3306 prepare 
```
- Run
```
sysbench /usr/share/sysbench/oltp_read_write.lua \
--tables=5 \
--table-size=2000000 \
--num-threads=10 \
--rand-type=uniform \
--db-driver=mysql \
--mysql-db=sysbench \
--mysql-user=sbuser \
--mysql_password=sbpass \
--mysql-host=127.0.0.1 \
--mysql-port=3306 \
run 
```
One liner
```
sysbench /usr/share/sysbench/oltp_read_write.lua --tables=5 --table-size=2000000 --num-threads=10 --rand-type=uniform --db-driver=mysql --mysql-db=sysbench --mysql-user=sbuser --mysql_password=sbpass --mysql-host=127.0.0.1 --mysql-port=3306 run  
```
- Result
```
SQL statistics:
    queries performed:
        read:                            53214
        write:                           4879
        other:                           17895
        total:                           75988
    transactions:                        3785   (377.24 per sec.)
    queries:                             75988  (7573.52 per sec.)
    ignored errors:                      16     (1.59 per sec.)
    reconnects:                          0      (0.00 per sec.)

General statistics:
    total time:                          10.0310s
    total number of events:              3785

Latency (ms):
         min:                                 12.97
         avg:                                 26.46
         max:                                 95.35
         95th percentile:                     40.37
         sum:                             100143.30

Threads fairness:
    events (avg/stddev):           378.5000/2.20
    execution time (avg/stddev):   10.0143/0.01
```
2. ProxySQL

```
sysbench \
--db-driver=mysql \
--mysql-user=sbuser \
--mysql_password=sbpass \
--mysql-db=sbtest \
--mysql-host=172.18.0.2 \
--mysql-port=16033 \
--tables=16 \
--table-size=10000 \
/usr/share/sysbench/oltp_read_write.lua prepare
```
- Run
```
sysbench /usr/share/sysbench/oltp_read_write.lua \
--tables=5 \
--table-size=2000000 \
--num-threads=10 \
--rand-type=uniform \
--db-driver=mysql \
--mysql-db=sysbench \
--mysql-user=sbuser \
--mysql_password=sbpass \
--mysql-host=127.0.0.1 \
--mysql-port=16033 \
run  
```
```
sysbench /usr/share/sysbench/oltp_read_write.lua --tables=5 --table-size=2000000 --num-threads=10 --rand-type=uniform --db-driver=mysql --mysql-db=sysbench --mysql-user=sbuser --mysql_password=sbpass --mysql-host=127.0.0.1 --mysql-port=16033 run  
```
- Result
```
SQL statistics:
    queries performed:
        read:                            51660
        write:                           4805
        other:                           17335
        total:                           73800
    transactions:                        3690   (366.80 per sec.)
    queries:                             73800  (7336.03 per sec.)
    ignored errors:                      0      (0.00 per sec.)
    reconnects:                          0      (0.00 per sec.)

General statistics:
    total time:                          10.0570s
    total number of events:              3690

Latency (ms):
         min:                                 16.07
         avg:                                 27.18
         max:                                101.67
         95th percentile:                     46.63
         sum:                             100277.32

Threads fairness:
    events (avg/stddev):           369.0000/9.54
    execution time (avg/stddev):   10.0277/0.02
``` 
- Query Cash
1. Find highest digest
`SELECT count_star,sum_time,hostgroup,digest,digest_text FROM stats_mysql_query_digest ORDER BY sum_time DESC;`
2. Add rules
`INSERT INTO mysql_query_rules (rule_id,active,digest,cache_ttl,apply) VALUES (7,1,'0xAC80A5EA0101522E',5000,1);`
3. `LOAD MYSQL QUERY RULES TO RUNTIME; SAVE MYSQL QUERY RULES TO DISK;`
### ToDo
1. Add mysql users to template (for recreation propose)
2. SSL
### Info
- ProxySQL query cache is an in-memory key-value storage that uses:
as key: a combination of username, schema, and query text. It is a hash derived from username, schema name and the query itself. Combining these ensure that users access only their resultsets and for the correct schema.
as value: the resultset returned by the backend (mysqld or another proxy).
- MySQL Query Cache
![Drag Racing](https://proxysql.com/wp-content/uploads/2017/05/query_cache.png)
- Any data manually added (by query) to ProxySql will be removed/replaced by data from proxysql.cnf.tmp on restart/reload