#!/bin/dash -e
if [ "$#" != 1 ]
then
  echo 'mirror.sh [timeout]'
  exit
fi
if [ ! -e /tmp/mirrors.lst ]
then
  wget -O /tmp/mirrors.lst cygwin.com/mirrors.lst
fi
export POSIXLY_CORRECT=1
awk '
function dom(url,   a, b, c, d) {
  split(url, a, "/")
  b = split(a[3], c, ".")
  if (length(c[b]) != 3)
    d = "Ω"
  do
    d = d c[b]
  while (--b)
  return d
}
function isort(ech,   fox, golf, hot) {
  for (fox in ech) {
    gol = ech[fox]
    hot = fox - 1
    while (hot && dom(ech[hot]) > dom(gol)) {
      ech[hot+1] = ech[hot]
      hot--
    }
    ech[hot+1] = gol
  }
}
BEGIN {
  FS = ";"
}
{
  a[NR] = $1
}
END {
  isort(a)
  for (b = 1; b <= 13; b++)
    if (a[b] ~ /http/)
      print a[b]
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
