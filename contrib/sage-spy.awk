#!/usr/local/bin/velour -f
function dom(url,   br, ch, pa, qu) {
  str_split("/", url, br)
  ch = str_split(".", br[3], pa)
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
    sb["sage-spy.awk <timeout>", "", "try 2.1 for FTP"]
    print arb_join(sb, RS)
    exit 1
  }
  while ("curl cygwin.com/mirrors.lst" | getline) {
    str_split(";", $0, ta)
    ar_bpush(xr, dom(ta[1]) ";" ta[1])
  }
  ar_sort(xr)
  for (ya = 1; http < 5 || ftp < 5; ya++) {
    str_split(";", xr[ya], zu)
    printf "%20s %.58s\r", "", zu[2]
    while ("timeout " ARGV[1] " curl -Is " zu[2] "x86_64/setup.xz" | getline) {
      str_split(", ", $0, ta)
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
