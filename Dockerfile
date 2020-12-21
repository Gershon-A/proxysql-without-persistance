FROM debian:stretch
LABEL maintainer="Gershon Alvais <gershon.alvais@testproject.com>"
ENV VERSION 2.0.15

RUN apt-get update && \
    apt-get install -y wget mysql-client inotify-tools procps gettext-base && \
    wget https://github.com/sysown/proxysql/releases/download/v${VERSION}/proxysql_${VERSION}-debian9_amd64.deb -O /opt/proxysql_${VERSION}-debian9_amd64.deb && \
    dpkg -i /opt/proxysql_${VERSION}-debian9_amd64.deb && \
    rm -f /opt/proxysql_${VERSION}-debian9_amd64.deb && \
    rm -rf /var/lib/apt/lists/*

# Static env variables. Value updates will need container restart to reflect changes
ENV PROXYSQL_CONF_CHECK_INTERVAL 60
ENV PROXYSQL_CONF_LIVE_RELOAD true
ENV PROXYSQL_ADMIN_USERNAME admin
ENV PROXYSQL_ADMIN_PASSWORD admin
ENV PROXYSQL_ADMIN_HOST "127.0.0.1"
ENV PROXYSQL_ADMIN_PORT "6032"
ENV PROXYSQL_MYSQL_THREADS 4
ENV PROXYSQL_MYSQL_STACKSIZE 1048576
ENV PROXYSQL_MYSQL_INTERFACES "0.0.0.0:6033;/tmp/proxysql.sock"
ENV PROXYSQL_WORKDIR /proxysql

# EXPOSE 6032 6033 6080
#  6032 - Admin
#  6033 - MySql
#  6080 - Web UI
EXPOSE 6032 6033 6080
RUN mkdir -p $PROXYSQL_WORKDIR

# Template to render /etc/proxysql.cnf. proxysql.cnf.tpl can contain
# env var subsitutions to be rendered from env vars and env vars loaded
# from $PROXYSQL_WORKDIR/secrets/secrets.env
COPY config/proxysql.cnf.tpl $PROXYSQL_WORKDIR/conf/proxysql.cnf.tpl
COPY config/secrets.env $PROXYSQL_WORKDIR/secrets/secrets.env

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["proxysql", "-f"]
