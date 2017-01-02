#!/bin/dash -e

xc() {
  awk 'BEGIN {d = "\47"; printf "\33[36m"; while (++j < ARGC) {
  k = split(ARGV[j], q, d); q[1]; for (x in q) printf "%s%s",
  q[x] ~ /^[[:alnum:]%+,./:=@_-]+$/ ? q[x] : d q[x] d, x < k ? "\\" d : ""
  printf j == ARGC - 1 ? "\33[m\n" : FS}}' "$@"
  "$@"
}

for q in /usr/local/http*/x86_64/release/make/make-*.tar.xz
do :
done
xc sage download

xc sage download mak

# exist=0
xc rm -fv "$q"
xc sage download make

# exist=1 sha=0
xc truncate -s0 "$q"
xc sage download make

# exist=1 sha=1
xc sage download make
