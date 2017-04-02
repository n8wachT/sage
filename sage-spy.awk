#!/usr/local/bin/awklib -f
function dom(url,   br, ch, pa, qu) {
  split(url, br, "/")
  ch = split(br[3], pa, ".")
  if (str_length(pa[ch]) != 3)
    qu = "Ω"
  do
    qu = qu pa[ch]
  while (--ch)
  return qu
}

BEGIN {
  if (ARGC != 2) {
    OFS = RS
    print "sage-spy.awk <timeout>", "", "try .5 for FTP"
    exit
  }
  FS = ";"
  while ("curl cygwin.com/mirrors.lst" | getline)
    xr[++NR] = dom($1) FS $1
  arr_sort(xr)
  for (ya = 1; http < 5 || ftp < 5; ya++) {
    split(xr[ya], zu)
    printf "%4s %.75s\r", "", zu[2]
    if (system("timeout " ARGV[1] " curl -Is " zu[2] ">/dev/null"))
      printf "\33[1;31m%s\33[m\n", "BAD"
    else
      printf "\33[1;32m%s\33[m\n", "GOOD"
    if (zu[2] ~ /^http/)
      http++
    else {
      ftp++
    }
  }
}
