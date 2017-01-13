#!/usr/bin/awk -f
function read(expr) {
  return getline < expr < 0 ? 0 : 1
}
function quote(str,   d, m, x, y, z) {
  d = "\47"; m = split(str, x, d)
  for (y in x) z = z d x[y] d (y < m ? "\\" d : "")
  return z
}
BEGIN {
  if (ARGC < 3) {
    print "sage-date.awk [mirror] [packages]"
    exit
  }
  if (!read("setup.ini")) {
    print "setup.ini not found"
    exit
  }
  for (ch = 2; ch < ARGC; ch++) {
    while (getline < "setup.ini") {
      if ($1 == "@" && $2 == ARGV[ch])
        de = 1
      if ($1 == "install:" && de) {
        while ("curl -I " quote(ARGV[1]) "/" $2 | getline ec)
          if (ec ~ "Last-Modified") {
            print ARGV[ch] ";", ec
          }
        break
      }
    }
  }
}
