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

ENV TTRSS_DB_TYPE="pgsql"
ENV TTRSS_DB_HOST="db"
ENV TTRSS_DB_USER="%DB_USER"
ENV TTRSS_DB_NAME="%DB_NAME"
ENV TTRSS_DB_PASS="%DB_PASS"
ENV TTRSS_DB_PORT="5432"

# config.php defaults
ENV TTRSS_MYSQL_CHARSET="UTF8"
ENV TTRSS_SELF_URL_PATH="%SELF_URL_PATH"
ENV TTRSS_SINGLE_USER_MODE=""
ENV TTRSS_SIMPLE_UPDATE_MODE=""
ENV TTRSS_PHP_EXECUTABLE="/usr/bin/php"
ENV TTRSS_LOCK_DIRECTORY="lock"
ENV TTRSS_CACHE_DIR="cache"
ENV TTRSS_ICONS_DIR="feed-icons"
ENV TTRSS_ICONS_URL="feed-icons"
ENV TTRSS_AUTH_AUTO_CREATE="true"
ENV TTRSS_AUTH_AUTO_LOGIN="true"
ENV TTRSS_FORCE_ARTICLE_PURGE="0"
ENV TTRSS_ENABLE_REGISTRATION=""
ENV TTRSS_REG_NOTIFY_ADDRESS="user@your.domain.dom"
ENV TTRSS_REG_MAX_USERS="10"
ENV TTRSS_SESSION_COOKIE_LIFETIME="86400"
ENV TTRSS_SMTP_FROM_NAME="Tiny Tiny RSS"
ENV TTRSS_SMTP_FROM_ADDRESS="noreply@your.domain.dom"
ENV TTRSS_DIGEST_SUBJECT="[tt-rss] New headlines for last 24 hours"
ENV TTRSS_CHECK_FOR_UPDATES="true"
ENV TTRSS_ENABLE_GZIP_OUTPUT=""
ENV TTRSS_PLUGINS="auth_internal, note, nginx_xaccel"
ENV TTRSS_LOG_DESTINATION="sql"
ENV TTRSS_CONFIG_VERSION="26"

CMD /startup.sh
