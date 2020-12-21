datadir="/var/lib/proxysql"

admin_variables=
{
        admin_credentials="${PROXYSQL_ADMIN_USERNAME}:${PROXYSQL_ADMIN_PASSWORD}"
        mysql_ifaces="${PROXYSQL_ADMIN_HOST}:${PROXYSQL_ADMIN_PORT}"
        refresh_interval=2000
}

mysql_variables=
{
        threads=${PROXYSQL_MYSQL_THREADS}
        max_connections=2048
        default_query_delay=0
        default_query_timeout=36000000
        have_compress=true
        poll_timeout=2000
        interfaces="${PROXYSQL_MYSQL_INTERFACES}"
        default_schema="information_schema"
        stacksize=${PROXYSQL_MYSQL_STACKSIZE}
        server_version="5.7"
        connect_timeout_server=10000
        monitor_history=60000
        monitor_connect_interval=200000
        monitor_ping_interval=200000
        ping_interval_server_msec=10000
        ping_timeout_server=200
        commands_stats=true
        sessions_sort=true
        autocommit_false_is_transaction=true
        init_connect="SET SESSION TX_ISOLATION='READ-COMMITTED'"
        monitor_username="${proxysql_monitor_username}"
        monitor_password="${proxysql_monitor_password}"
        enforce_autocommit_on_reads=true
        free_connections_pct=110
# ToDo
	ssl_p2s_ca=""
	ssl_p2s_cert=""
        ssl_p2s_key=""
        ssl_p2s_cipher="ECDHE-RSA-AES128-GCM-SHA256"        
}

mysql_servers =
(
        {
		address = "${db1_host}"
		port = ${db1_port}
		weight = 1
		hostgroup = 1
		max_connections = 1000
        },
                {
		address = "${db2_host}"
		port = ${db2_port}
		weight = 1
		hostgroup = 1
		max_connections = 1000
        },
                {
		address = "${db3_host}"
		port = ${db3_port}
		weight = 1
		hostgroup = 1
		max_connections = 1000
        }
)

mysql_users =
(
        { 
                username = "${db1_username}" 
                password = "${db1_password}" 
                default_hostgroup = 20 
                active = 1
        },
        { 
                username = "${db2_username}" 
                password = "${db2_password}" 
                default_hostgroup = 20 
                active = 1 
        },
        # ProxySQL Monitoring User
        {
		username = "${mysql_monitor_username}"
		password = "${mysql_monitor_password}"
		default_hostgroup = 0
        },
        # Benchmarking User
	{
		username = "${proxysql_sbuser}"
		password = "${proxysql_sbpass}"
		default_hostgroup = 1
	}
)

mysql_query_rules =
(
        {
                rule_id=100
                active=1
                proxy_port=6033
                destination_hostgroup=10
                apply=1
                username="${db1_username}"
        },
        {
                rule_id=200
                active=1
                proxy_port=6033
                destination_hostgroup=20
                apply=1
                username="${db2_username}"
        },
        # Benchmarking
        {
                rule_id=300
                active=1
                proxy_port=6033
                destination_hostgroup=1
                cache_ttl=2000
                apply=1
                username="${proxysql_sbuser}"
        },
        # mysql_query_rules
                {
                rule_id=5
                active=1
                digest=0xFAD1519E4760CBDE
                proxy_port=6033
                destination_hostgroup=1
                cache_ttl=2000
                apply=1
                username="${proxysql_sbuser}"
        },
        {
                rule_id=10
                active=1
                digest=0xC2A4F66B0CA11A02
                cache_ttl=2000
                apply=1

        },
        {
                rule_id=11
                active=1
                digest=0x9AF59B998A3688ED
                cache_ttl=5000
                apply=1

        },
        {
                rule_id=12
                active=1
                digest=0x03744DC190BC72C7
                cache_ttl=5000
                apply=1

        },
        {
                rule_id=13
                active=1
                digest=0x9D058B6F3BC2F754
                cache_ttl=5000
                apply=1

        },
        {
                rule_id=14
                active=1
                digest=0x0250CB4007721D69
                cache_ttl=5000
                apply=1

        }
)