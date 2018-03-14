#!/usr/local/bin/velour -f
function dom(url,   br, ch, pa, qu) {
  s_split(url, br, "/")
  ch = s_split(br[3], pa, ".")
  if (s_length(pa[ch]) != 3) {
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
    print ac_join(sb, RS)
    exit 1
  }
  while ("curl cygwin.com/mirrors.lst" | getline) {
    s_split($0, ta, ";")
    a_push(xr, dom(ta[1]) ";" ta[1])
  }
  a_sort(xr)
  for (ya = 1; http < 5 || ftp < 5; ya++) {
    s_split(xr[ya], zu, ";")
    printf "%20s %.58s\r", "", zu[2]
    while ("curl -Ism" ARGV[1] " " zu[2] "x86_64/setup.xz" | getline) {
      s_split($0, ta, ", ")
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
