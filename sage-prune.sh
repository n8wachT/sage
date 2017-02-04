#!/bin/dash -e
. stdlib.sh
j=$(mktemp)
sage category Base | xargs sage depends | awk '$0=$NF' | sort -u > "$j"
sage list | awk '$0=$1' FS='-[[:digit:]]' | grep -Fvxf "$j" | xargs sage remove
xtrace rm -rf /usr/x86_64-w64-mingw32
