#!/bin/dash -e
if [ "$#" = 0 ]
then
  cat <<'eof'
sage-cost.sh <base> <packages>

if base is "no", exclude base packages from the output; otherwise include them
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
