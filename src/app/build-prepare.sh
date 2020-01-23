#!/bin/sh

DST_DIR=/src/tt-rss
SRC_REPO=https://git.tt-rss.org/fox/tt-rss.git

if [ ! -d $DST_DIR ]; then
	mkdir -p $DST_DIR
	git clone $SRC_REPO $DST_DIR
else
	cd $DST_DIR && \
		git config core.filemode false && \
		git pull origin master
fi

if [ ! -d $DST_DIR/plugins.local/nginx_xaccel ]; then
	git clone https://git.tt-rss.org/fox/ttrss-nginx-xaccel.git $DST_DIR/plugins.local/nginx_xaccel
else
	cd $DST_DIR/plugins.local/nginx_xaccel && \
		git config core.filemode false && \
	  	git pull origin master
fi

mkdir -p /var/www

