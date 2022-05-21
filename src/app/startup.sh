#!/bin/sh -e

while ! pg_isready -h $TTRSS_DB_HOST -U $TTRSS_DB_USER; do
	echo waiting until $TTRSS_DB_HOST is ready...
	sleep 3
done

# We don't need those here (HTTP_HOST would cause false SELF_URL_PATH check failures)
unset HTTP_PORT
unset HTTP_HOST

if ! id app >/dev/null 2>&1; then
	addgroup -g $OWNER_GID app
	adduser -D -h /var/www/html -G app -u $OWNER_UID app
fi

update-ca-certificates || true

DST_DIR=/var/www/html/tt-rss
SRC_DIR=/src/tt-rss/

[ -e $DST_DIR ] && rm -f $DST_DIR/.app_is_ready

export PGPASSWORD=$TTRSS_DB_PASS

[ ! -e /var/www/html/index.php ] && cp ${SCRIPT_ROOT}/index.php /var/www/html

if [ ! -d $DST_DIR ]; then
	rsync -a \
		$SRC_DIR/ $DST_DIR/
else
	rsync -a --delete \
		--exclude cache \
		--exclude lock \
		--exclude feed-icons \
		--exclude plugins.local \
		--exclude templates.local \
		--exclude themes.local \
		$SRC_DIR/ $DST_DIR/

	rsync -a --delete \
		$SRC_DIR/plugins.local/nginx_xaccel $DST_DIR/plugins.local/nginx_xaccel
fi

for d in cache lock feed-icons plugins.local themes.local; do
	mkdir -p $DST_DIR/$d
done

if [ -z "$TTRSS_NO_STARTUP_PLUGIN_UPDATES" ]; then
	echo updating all local plugins...

	find $DST_DIR/plugins.local -mindepth 1 -maxdepth 1 -type d | while read PLUGIN; do
		if [ -d $PLUGIN/.git ]; then
			echo updating $PLUGIN...

			cd $PLUGIN && \
				sudo -u app git config core.filemode false && \
				sudo -u app git config pull.rebase false && \
				sudo -u app git pull origin master || echo warning: attempt to update plugin $PLUGIN failed.
		fi
	done
else
	echo skipping local plugin updates, disabled.
fi

cp ${SCRIPT_ROOT}/config.docker.php $DST_DIR/config.php
chmod 644 $DST_DIR/config.php

chown -R $OWNER_UID:$OWNER_GID $DST_DIR \
	/var/log/php8

for d in cache lock feed-icons; do
	chmod 777 $DST_DIR/$d
	find $DST_DIR/$d -type f -exec chmod 666 {} \;
done

PSQL="psql -q -h $TTRSS_DB_HOST -U $TTRSS_DB_USER $TTRSS_DB_NAME"

$PSQL -c "create extension if not exists pg_trgm"

RESTORE_SCHEMA=${SCRIPT_ROOT}/restore-schema.sql.gz

if [ -r $RESTORE_SCHEMA ]; then
	$PSQL -c "drop schema public cascade; create schema public;"
	zcat $RESTORE_SCHEMA | $PSQL
fi

# this was previously generated
rm -f $DST_DIR/config.php.bak

if [ ! -z "${TTRSS_XDEBUG_ENABLED}" ]; then
	if [ -z "${TTRSS_XDEBUG_HOST}" ]; then
		export TTRSS_XDEBUG_HOST=$(ip ro sh 0/0 | cut -d " " -f 3)
	fi
	echo enabling xdebug with the following parameters:
	env | grep TTRSS_XDEBUG
	cat > /etc/php8/conf.d/50_xdebug.ini <<EOF
zend_extension=xdebug.so
xdebug.mode=develop,trace,debug
xdebug.start_with_request = yes
xdebug.client_port = ${TTRSS_XDEBUG_PORT}
xdebug.client_host = ${TTRSS_XDEBUG_HOST}
EOF
fi

sed -i.bak "s/^\(memory_limit\) = \(.*\)/\1 = ${PHP_WORKER_MEMORY_LIMIT}/" \
	/etc/php8/php.ini

sed -i.bak "s/^\(pm.max_children\) = \(.*\)/\1 = ${PHP_WORKER_MAX_CHILDREN}/" \
	/etc/php8/php-fpm.d/www.conf

cd $DST_DIR && sudo -E -u app php8 ./update.php --update-schema=force-yes

rm -f /tmp/error.log && mkfifo /tmp/error.log && chown app:app /tmp/error.log

(tail -q -f /tmp/error.log >> /proc/1/fd/2) &

touch $DST_DIR/.app_is_ready

exec /usr/sbin/php-fpm8 --nodaemonize --force-stderr
