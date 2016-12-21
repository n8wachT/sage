#!/bin/dash -e
xc() {
  awk 'BEGIN {
    x = "\47"; printf "\33[36m"; while (++i < ARGC) {
      y = split(ARGV[i], z, x); for (j in z) {
        printf z[j] ~ /[^[:alnum:]%+,./:=@_-]/ ? x z[j] x : z[j]
        if (j < y) printf "\\" x
      } printf i == ARGC - 1 ? "\33[m\n" : FS
    }
  }' "$@"
  "$@"
}
j=$(mktemp)
sage category Base | xargs sage depends | awk '$0=$NF' | sort -u > "$j"
sage list | grep -Fvxf "$j" | xargs sage remove
xc rm -rf /usr/x86_64-w64-mingw32
