#!/bin/dash -e
if [ "$#" -lt 2 ]
then
  cat <<'eof'
SYNOPSIS
  sage-cost.sh <base> <packages>

BASE
  ex   exclude base packages
  in   include base packages
eof
  exit 1
fi
br=$1
shift
wh=$(mktemp)

if [ "$br" = no ]
then
  sage category Base |
  xargs sage depends |
  awk '$0=$NF' |
  sort -u > "$wh"
fi

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
