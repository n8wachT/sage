#!/bin/dash

pause() {
  printf '\nPress Enter to continue...\n'
  read br
  printf '\33c'
}

xtrace() {
  awk 'BEGIN {d = "\47"; printf "\33[36m"; while (++q < ARGC) {
  x = split(ARGV[q], y, d); y[1]; for (z in y) printf "%s%s",
  !x || y[z] ~ /[^[:alnum:]%+,./:=@_-]/ ? d y[z] d : y[z], z < x ? "\\" d : ""
  printf q == ARGC - 1 ? "\33[m\n" : FS}}' "$@"
  "$@"
}
