#!/bin/sh -ex

while ! pg_isready -h $DB_HOST -U $DB_USER; do
	echo waiting until $DB_HOST is ready...
	sleep 3
done

if ! id app; then
	addgroup -g $OWNER_GID app
	adduser -D -h /var/www/html -G app -u $OWNER_UID app
fi

DST_DIR=/var/www/html/tt-rss
SRC_DIR=/src/tt-rss/

[ -e $DST_DIR ] && rm -f $DST_DIR/.app_is_ready

export PGPASSWORD=$DB_PASS 

[ ! -e /var/www/html/index.php ] && cp /index.php /var/www/html

if [ ! -d $DST_DIR ]; then
	rsync -aP \
		$SRC_DIR/ $DST_DIR/
else
	rsync -aP --delete \
		--exclude cache \
		--exclude lock \
		--exclude feed-icons \
		--exclude plugins.local \
		--exclude templates.local \
		--exclude themes.local \
		--exclude config.php \
		$SRC_DIR/ $DST_DIR/

	rsync -aP --delete \
		$SRC_DIR/plugins.local/nginx_xaccel $DST_DIR/plugins.local/nginx_xaccel
fi

for d in cache lock feed-icons plugins.local themes.local; do
	mkdir -p $DST_DIR/$d
done

for d in cache lock feed-icons; do
	chmod 777 $DST_DIR/$d
	find $DST_DIR/$d -type f -exec chmod 666 {} \;
done

chown -R $OWNER_UID:$OWNER_GID $DST_DIR \
	/var/log/php7	

PSQL="psql -q -h $DB_HOST -U $DB_USER $DB_NAME"

$PSQL -c "create extension if not exists pg_trgm"

RESTORE_SCHEMA=/var/www/html/tt-rss/backups/restore-schema.sql.gz

if [ -r $RESTORE_SCHEMA ]; then
	zcat $RESTORE_SCHEMA | $PSQL
elif ! $PSQL -c 'select * from ttrss_version'; then
	$PSQL < /var/www/html/tt-rss/schema/ttrss_schema_pgsql.sql
fi

SELF_URL_PATH=$(echo $SELF_URL_PATH | sed -e 's/[\/&]/\\&/g')

if [ ! -s $DST_DIR/config.php ]; then
	sed \
		-e "s/define('DB_HOST'.*/define('DB_HOST', '$DB_HOST');/" \
		-e "s/define('DB_USER'.*/define('DB_USER', '$DB_USER');/" \
		-e "s/define('DB_NAME'.*/define('DB_NAME', '$DB_NAME');/" \
		-e "s/define('DB_PASS'.*/define('DB_PASS', '$DB_PASS');/" \
		-e "s/define('DB_TYPE'.*/define('DB_TYPE', 'pgsql');/" \
		-e "s/define('DB_PORT'.*/define('DB_PORT', 5432);/" \
		-e "s/define('PLUGINS'.*/define('PLUGINS', 'auth_internal, note, nginx_xaccel');/" \
		-e "s/define('SELF_URL_PATH'.*/define('SELF_URL_PATH','$SELF_URL_PATH');/" \
		< $DST_DIR/config.php-dist > $DST_DIR/config.php

	cat >> $DST_DIR/config.php << EOF
		define('NGINX_XACCEL_PREFIX', '/tt-rss');
EOF
else
	sed \
		-e "s/define('SELF_URL_PATH'.*/define('SELF_URL_PATH','$SELF_URL_PATH');/" \
		-i.bak $DST_DIR/config.php
fi

cd $DST_DIR && sudo -u app php ./update.php --update-schema=force-yes

touch $DST_DIR/.app_is_ready

sudo -u app /usr/sbin/php-fpm7 -F

