FROM mariadb:11.4

ENV MARIADB_ROOT_PASSWORD=powerace_root
ENV MARIADB_USER=powerace
ENV MARIADB_PASSWORD=powerace

COPY data/powerace-data.sql /tmp/powerace-data.sql

RUN set -eux; \
    mkdir -p /var/lib/mysql /run/mysqld; \
    chown -R mysql:mysql /var/lib/mysql /run/mysqld; \
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql --auth-root-authentication-method=normal --skip-test-db; \
    mariadbd --user=mysql --datadir=/var/lib/mysql --skip-networking --socket=/tmp/mysql.sock & \
    pid="$!"; \
    for i in $(seq 1 60); do \
        if mariadb-admin --socket=/tmp/mysql.sock ping --silent; then \
            break; \
        fi; \
        sleep 1; \
    done; \
    mariadb --socket=/tmp/mysql.sock -uroot < /tmp/powerace-data.sql; \
    mariadb --socket=/tmp/mysql.sock -uroot -e "CREATE USER IF NOT EXISTS 'powerace'@'%' IDENTIFIED BY 'powerace'; GRANT SELECT, SHOW VIEW ON *.* TO 'powerace'@'%'; ALTER USER 'root'@'localhost' IDENTIFIED BY 'powerace_root'; FLUSH PRIVILEGES;"; \
    mariadb-admin --socket=/tmp/mysql.sock -uroot -ppowerace_root shutdown; \
    wait "$pid" || true; \
    rm -f /tmp/powerace-data.sql

EXPOSE 3306
