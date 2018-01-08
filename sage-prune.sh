#!/usr/local/bin/shlib
z=$(mktemp)
sage category Base | xargs sage depends | awk '$0=$NF' | sort -u > "$z"
sage list | awk '$0=$1' FS='-[[:digit:]]' | grep -Fvxf "$z" | xargs sage remove
sh_trace rm -frv /usr/local/lib /usr/x86_64-w64-mingw32
