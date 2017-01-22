#!/usr/bin/awk -f
function dom(url,   q, x, y, z) {
  split(url, q, "/")
  x = split(q[3], y, ".")
  if (length(y[x]) != 3)
    z = "Ω"
  do
    z = z y[x]
  while (--x)
  return z
}

function exists(file) {
  return getline < file < 0 ? 0 : 1
}

function insertion_sort(arr,   x, y, z) {
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
    print "sage-spy.awk [timeout]"
    exit
  }
  FS = ";"
  while ("curl cygwin.com/mirrors.lst" | getline)
    q[++NR] = $1
  insertion_sort(q)
  while (++z < 13) {
    if (q[z] ~ /http/) {
      printf "\t%s\r", q[z]
      if (system("timeout " ARGV[1] " curl -Is " q[z] ">/dev/null"))
        printf "\33[1;31m%s\33[m\n", "BAD"
      else {
        printf "\33[1;32m%s\33[m\n", "GOOD"
      }
    }
  }
}
