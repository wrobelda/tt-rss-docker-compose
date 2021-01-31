#!/bin/sh

grep define config.php-dist | sed -e "s/[ \t]*define('\([A-Z_]\+\)', ['\"]\?\([^'\")]\+\).*/ENV \1=\"\2\"/"
