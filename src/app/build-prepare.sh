#!/bin/sh -e

DST_DIR=/src/tt-rss

mkdir -p $DST_DIR

echo cloning $ORIGIN_REPO_MAIN to $DST_DIR...
git clone --branch master --depth 1 $ORIGIN_REPO_MAIN $DST_DIR
echo built for: $(git --git-dir=$DST_DIR/.git --no-pager log --pretty='%H' -n1 HEAD)

echo cloning $ORIGIN_REPO_XACCEL to $DST_DIR/plugins.local/nginx_xaccel...
git clone --branch master --depth 1 $ORIGIN_REPO_XACCEL $DST_DIR/plugins.local/nginx_xaccel
echo built for: $(git --git-dir=$DST_DIR/plugins.local/nginx_xaccel/.git --no-pager log --pretty='%H' -n1 HEAD)

mkdir -p /var/www
