#!/bin/dash -e
if [ "$#" != 1 ]
then
  echo 'sage-cost.sh [package]'
  exit
fi
wh=$(mktemp)

sage category Base |
xargs sage depends |
awk '$0=$NF' |
sort -u > "$wh"

sage depends "$1" |
awk '$0=$NF' |
sort -u |
grep -Fvxf "$wh" |
xargs sage show |
awk '
$1 == "@" {
  xr = $2
}
$1 == "install:" && xr {
  printf "%9\47d %s\n", $3, xr
  xr = ""
  ya += 1
  zu += $3
}
END {
  printf "\npackages: %d\n", ya
  printf "bytes: %\47d\n", zu
}
'
