#!/usr/local/bin/awklib -f
function dom(url,   br, ch, pa, qu) {
  split(url, br, "/")
  ch = split(br[3], pa, ".")
  if (str_length(pa[ch]) != 3) {
    qu = "Ω"
  }
  do {
    qu = qu pa[ch]
  }
  while (--ch)
  return qu
}

BEGIN {
  if (ARGC != 2) {
    print "sage-spy.awk <timeout>"
    print ""
    print "try 2 for FTP"
    exit 1
  }
  while ("curl cygwin.com/mirrors.lst" | getline) {
    split($0, ta, ";")
    arr_bpush(xr, dom(ta[1]) ";" ta[1])
  }
  arr_sort(xr)
  for (ya = 1; http < 5 || ftp < 5; ya++) {
    split(xr[ya], zu, ";")
    printf "%20s %.58s\r", "", zu[2]
    while ("timeout " ARGV[1] " curl -Is " zu[2] "x86_64/setup.xz" | getline) {
      split($0, ta, ", ")
      if (tolower(ta[1]) ~ "last-modified") {
        printf "%.20s\r", ta[2]
      }
    }
    print ""
    if (zu[2] ~ /^http/) {
      http++
    }
    else {
      ftp++
    }
  }
}
