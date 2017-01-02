#!/bin/dash -e
if [ "$#" != 1 ]
then
  echo 'sage-spy.sh [timeout]'
  exit
fi
if [ ! -f /tmp/mirrors.lst ]
then
  wget -O /tmp/mirrors.lst cygwin.com/mirrors.lst
fi
awk '
function dom(url,   br, pa, xr, ya) {
  split(url, br, "/")
  pa = split(br[3], xr, ".")
  if (length(xr[pa]) != 3)
    ya = "Ω"
  do
    ya = ya xr[pa]
  while (--pa)
  return ya
}
function asrt(br,   pa, xr, ya) {
  for (pa in br) {
    xr = br[pa]
    ya = pa - 1
    while (ya && dom(br[ya]) > dom(xr)) {
      br[ya + 1] = br[ya]
      ya--
    }
    br[ya + 1] = xr
  }
}
BEGIN {
  FS = ";"
}
{
  zu[NR] = $1
}
END {
  asrt(zu)
  for (pa = 1; pa <= 13; pa++) {
    if (zu[pa] ~ /http/) {
      print zu[pa]
    }
  }
}
' /tmp/mirrors.lst |
while read each
do
  # dont sort these by length - we want the URL closer to top anyway
  printf '\t%s\r' "$each"
  if wget -q --spider --tries 1 --timeout "$1" "$each"
  then
    printf '\33[1;32m%s\33[m\n' GOOD
  else
    printf '\33[1;31m%s\33[m\n' BAD
  fi
done
