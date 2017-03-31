#!/usr/local/bin/awklib -f
function dom(url,   q, x, y, z) {
  split(url, q, "/")
  x = split(q[3], y, ".")
  if (str_len(y[x]) != 3)
    z = "Ω"
  do
    z = z y[x]
  while (--x)
  return z
}

function insertion_sort_c(arr,   x, y, z) {
  for (x in arr) {
    y = arr[x]
    z = x - 1
    while (z && dom(arr[z]) > dom(y)) {
      arr[z + 1] = arr[z]
      z--
    }
    arr[z + 1] = y
  }
}

BEGIN {
  if (ARGC != 2) {
    OFS = RS
    print "sage-spy.awk [timeout]", "", "try .5 for FTP"
    exit
  }
  FS = ";"
  while ("curl cygwin.com/mirrors.lst" | getline)
    q[++NR] = $1
  insertion_sort(q)
  for (z = 1; http < 5 || ftp < 5; z++) {
    printf "\t%s\r", q[z]
    if (system("timeout " ARGV[1] " curl -Is " q[z] ">/dev/null"))
      printf "\33[1;31m%s\33[m\n", "BAD"
    else
      printf "\33[1;32m%s\33[m\n", "GOOD"
    if (q[z] ~ /^http/)
      http++
    else {
      ftp++
    }
  }
}
