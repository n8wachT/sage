#!/bin/dash -e
if [ "$#" = 0 ]
then
  echo 'sage-cost.sh [packages]'
  exit
fi
wh=$(mktemp)

sage category Base |
xargs sage depends |
awk '$0=$NF' |
sort -u > "$wh"

sage depends "$@" |
awk '$0=$NF' |
sort -u |
grep -Fvxf "$wh" |
xargs sage show |
awk '
$1 == "@" {
  xr = $2
}
$1 == "install:" && xr {
  printf "%11\47d %s\n", $3, xr
  xr = ""
  ya += 1
  zu += $3
}
END {
  printf "\npackages: %d\n", ya
  printf "bytes: %\47d\n", zu
}
'
