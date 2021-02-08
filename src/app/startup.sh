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
		--exclude config.php \
		$SRC_DIR/ $DST_DIR/

	rsync -a --delete \
		$SRC_DIR/plugins.local/nginx_xaccel $DST_DIR/plugins.local/nginx_xaccel
fi

for d in cache lock feed-icons plugins.local themes.local; do
	mkdir -p $DST_DIR/$d
done

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
	zcat $RESTORE_SCHEMA | $PSQL
elif ! $PSQL -c 'select * from ttrss_version'; then
	$PSQL < /var/www/html/tt-rss/schema/ttrss_schema_pgsql.sql
fi

if [ ! -s $DST_DIR/config.php ]; then
	cp ${SCRIPT_ROOT}/config.docker.php $DST_DIR/config.php
else
	if ! egrep -q 'SELF_URL_PATH.*getenv' $DST_DIR/config.php; then
		echo -e "\nWARNING: you're using old-style config.php, overrides via .env will not work.\n" >/dev/stderr
	else
		cp ${SCRIPT_ROOT}/config.docker.php $DST_DIR/config.php
	fi
fi

# this was previously generated
rm -f $DST_DIR/config.php.bak

cd $DST_DIR && sudo -E -u app php8 ./update.php --update-schema=force-yes

touch $DST_DIR/.app_is_ready

sudo -E -u app /usr/sbin/php-fpm8 -F

