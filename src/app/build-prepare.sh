#!/bin/sh

DST_DIR=/src/tt-rss

mkdir -p $DST_DIR

git clone --branch master --depth 1 https://git.tt-rss.org/fox/tt-rss.git $DST_DIR
git clone --branch master --depth 1 https://git.tt-rss.org/fox/ttrss-nginx-xaccel.git $DST_DIR/plugins.local/nginx_xaccel

mkdir -p /var/www
