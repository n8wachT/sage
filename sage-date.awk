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
  while (getline < "setup.ini") {
    if ($1 == "@")
      br = $2
    if ($1 == "install:" && br) {
      ch[br] = $2
      br = ""
    }
  }
  for (de = 2; de < ARGC; de++) {
    while ("curl -I " quote(ARGV[1]) "/" ch[ARGV[de]] | getline) {
      if ($1 == "Last-Modified:") {
        print ARGV[de] ";", $0
      }
    }
  }
}
