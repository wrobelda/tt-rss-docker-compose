#!/bin/sh

grep define config.php-dist | sed -e "s/[ \t]*define('\([A-Z_]\+\)', ['\"]\?\([^'\")]\+\).*/ENV TTRSS_\1=\"\2\"/" \
  -e 's/"false"/""/'
