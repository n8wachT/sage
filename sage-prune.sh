#!/bin/dash -e
xc() {
  awk 'BEGIN {d = "\47"; printf "\33[36m"; while (++j < ARGC) {
  k = split(ARGV[j], q, d); q[1]; for (x in q) printf "%s%s",
  q[x] ~ /^[[:alnum:]%+,./:=@_-]+$/ ? q[x] : d q[x] d, x < k ? "\\" d : ""
  printf j == ARGC - 1 ? "\33[m\n" : FS}}' "$@"
  "$@"
}
j=$(mktemp)
sage category Base | xargs sage depends | awk '$0=$NF' | sort -u > "$j"
sage list | grep -Fvxf "$j" | xargs sage remove
xc rm -rf /usr/x86_64-w64-mingw32
