#!/bin/sh -e

DST_DIR=/src/tt-rss

mkdir -p $DST_DIR

echo requested commit: $ORIGIN_COMMIT

echo cloning $ORIGIN_REPO_MAIN to $DST_DIR...
git clone --branch master --depth 1 $ORIGIN_REPO_MAIN $DST_DIR

BUILD_COMMIT=$(git --git-dir=$DST_DIR/.git --no-pager log --pretty='%H' -n1 HEAD)

echo built for: $BUILD_COMMIT

if [ ! -z "$ORIGIN_COMMIT" -a "$ORIGIN_COMMIT" != "$BUILD_COMMIT" ]; then
	echo actual build commit differs from requested commit, bailing out.
	exit 1
fi

echo cloning $ORIGIN_REPO_XACCEL to $DST_DIR/plugins.local/nginx_xaccel...
git clone --branch master --depth 1 $ORIGIN_REPO_XACCEL $DST_DIR/plugins.local/nginx_xaccel
echo built for: $(git --git-dir=$DST_DIR/plugins.local/nginx_xaccel/.git --no-pager log --pretty='%H' -n1 HEAD)

mkdir -p /var/www
