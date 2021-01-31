FROM alpine:3.12
EXPOSE 9000/tcp

RUN apk add --no-cache dcron php7 php7-fpm \
	php7-pdo php7-gd php7-pgsql php7-pdo_pgsql php7-mbstring \
	php7-intl php7-xml php7-curl php7-session \
	php7-dom php7-fileinfo php7-json php7-iconv \
	php7-pcntl php7-posix php7-zip php7-openssl \
	git postgresql-client sudo

ADD startup.sh /
ADD updater.sh /
ADD index.php /
ADD dcron.sh /
ADD backup.sh /etc/periodic/weekly/backup
ADD config.docker.php /

RUN sed -i.bak 's/^listen = 127.0.0.1:9000/listen = 9000/' /etc/php7/php-fpm.d/www.conf
RUN sed -i.bak 's/\(memory_limit =\) 128M/\1 256M/' /etc/php7/php.ini
RUN sed -i.bak 's/;clear_env = .*/clear_env = no/i' /etc/php7/php-fpm.d/www.conf

RUN mkdir -p /var/www
RUN mkdir -p /opt/tt-rss/config.d

ENV OWNER_UID=1000
ENV OWNER_GID=1000

ENV DB_TYPE="pgsql"
ENV DB_HOST="db"
ENV DB_USER="%DB_USER"
ENV DB_NAME="%DB_NAME"
ENV DB_PASS="%DB_PASS"
ENV DB_PORT="5432"

# config.php defaults
ENV MYSQL_CHARSET="UTF8"
ENV SELF_URL_PATH="%SELF_URL_PATH"
ENV SINGLE_USER_MODE="false"
ENV SIMPLE_UPDATE_MODE="false"
ENV PHP_EXECUTABLE="/usr/bin/php"
ENV LOCK_DIRECTORY="lock"
ENV CACHE_DIR="cache"
ENV ICONS_DIR="feed-icons"
ENV ICONS_URL="feed-icons"
ENV AUTH_AUTO_CREATE="true"
ENV AUTH_AUTO_LOGIN="true"
ENV FORCE_ARTICLE_PURGE="0"
ENV ENABLE_REGISTRATION="false"
ENV REG_NOTIFY_ADDRESS="user@your.domain.dom"
ENV REG_MAX_USERS="10"
ENV SESSION_COOKIE_LIFETIME="86400"
ENV SMTP_FROM_NAME="Tiny Tiny RSS"
ENV SMTP_FROM_ADDRESS="noreply@your.domain.dom"
ENV DIGEST_SUBJECT="[tt-rss] New headlines for last 24 hours"
ENV CHECK_FOR_UPDATES="true"
ENV ENABLE_GZIP_OUTPUT="false"
ENV PLUGINS="auth_internal, note"
ENV LOG_DESTINATION="sql"
ENV CONFIG_VERSION="26"

CMD /startup.sh
