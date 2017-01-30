#!/bin/dash -e
# -*- sh -*-

webreq() {
  if wget -h >/dev/null 2>&1
  then
    wget "$1"/"$2"
  else
    ftp -Av ftp.gtlib.gatech.edu <<eof |
hash
get pub/cygwin/$2
eof
    awk '
    function ceil(x,   y) {
      y = int(x); return y < x ? y + 1 : y
    }
    BEGIN {
      RS = "#"
      FS = "[( ]"
    }
    NR == 1 {
      q = $(NF - 1) / (2048 * 100)
    }
    NR % ceil(q) == 0 {
      printf "%d%%\r", ++x
    }
    END {
      print ""
    }
    '
  fi
}

getwd() {
  awk '
  function encodeURIComponent(str,   g, q, y, z) {
    while (g++ < 125) q[sprintf("%c", g)] = g
    while (g = substr(str, ++y, 1))
      z = z (g ~ /[[:alnum:]_.!~*\47()-]/ ? g : sprintf("%%%02X", q[g]))
    return z
  }
  function quote(str,   d, m, x, y, z) {
    d = "\47"; m = split(str, x, d)
    for (y in x) z = z d x[y] (y < m ? d "\\" d : d)
    return z
  }
  BEGIN {
    FS = "\t"
  }
  {
    if (/\t/)
      x[y] = x[y] ? x[y] "," $2 : $2
    else {
      sub("-", "")
      y = $0
    }
  }
  END {
    for (y in x) {
      print y "=" quote(x[y])
      print "e" y "=" quote(encodeURIComponent(x[y]))
    }
  }
  ' /etc/setup/setup.rc > /etc/setup/setup.sh
}

setwd() {
  if [ ! -f /etc/setup/setup.sh ] ||
    find /etc/setup/setup.sh -newer /etc/setup/setup.rc -exec false {} +
  then
    getwd
  fi
  . /etc/setup/setup.sh
  mkdir -p "$lastcache"/"$elastmirror"/"$arch"
  cd "$lastcache"/"$elastmirror"/"$arch"
}

no_targets() {
  if [ -s /tmp/tar.lst ]
  then false
  else echo 'No packages found.'
  fi
}

_update() {
  setwd
  webreq "$lastmirror" "$arch"/setup.bz2
  bunzip2 < setup.bz2 > setup.ini
  echo 'Updated setup.ini'
}

_category() {
  setwd
  awk '
  BEGIN {
    if (!getline b < ARGV[2]) exit
    ARGC--
  }
  {
    if ($1 == "@")
      q = $2
    if ($1 == "category:") {
      do
        if ($NF == b) {
          print q
        }
      while (--NF)
    }
  }
  ' setup.ini /tmp/tar.lst
}

_list() {
  awk '
  BEGIN {
    ARGC--
    getline x < ARGV[2]
  }
  NR > 1 && $1 ~ x {
    split($2, y, /\.[[:alpha:]]/)
    print y[1]
  }
  ' /etc/setup/installed.db /tmp/tar.lst
}

_listall() {
  setwd
  awk '
  BEGIN {
    if (!getline q < ARGV[2]) exit
    ARGC--
  }
  $1 == "@" && $2 ~ q {
    print $2
  }
  ' setup.ini /tmp/tar.lst
}

_listfiles() {
  if ! read b < /tmp/tar.lst
  then return
  fi
  setwd
  find .. -name "$b"'-*' |
  awk '
  END {
    system("tar tf " $0)
  }
  '
}

_show() {
  setwd
  awk '
  BEGIN {
    while (getline < ARGV[2]) x[$0]
    if (!$0) exit
    ARGC--
  }
  $1 == "@" {
    y = $2 in x ? 1 : 0
  }
  y
  ' setup.ini /tmp/tar.lst
}

smartmatch='
function smartmatch(diamond, rough,   x, y) {
  for (x in rough) y[rough[x]]
  return diamond in y
}
'

_depends() {
  setwd
  awk "$smartmatch"'
  function tree(package,   ec, ro, ta) {
    if (smartmatch(package, branch))
      return
    branch[++ec] = package
    for (ro in branch)
      printf branch[ro] (ro == ec ? RS : " > ")
    while (reqs[package, ++ta])
      tree(reqs[package, ta], ec)
    delete branch[ec--]
  }
  BEGIN {
    while (getline < ARGV[2]) xr[$0]
    if (!$0) exit
    ARGC--
  }
  {
    if ($1 == "@")
      ya = $2
    if ($1 == "requires:") {
      for (zu = 2; zu <= NF; zu++) {
        reqs[ya, zu - 1] = $zu
      }
    }
  }
  END {
    for (zu in xr) {
      tree(zu)
    }
  }
  ' setup.ini /tmp/tar.lst
}

_rdepends() {
  setwd
  awk "$smartmatch"'
  function rtree(package,   ec, ro, ta) {
    if (smartmatch(package, branch))
      return
    branch[++ec] = package
    for (ro in branch)
      printf branch[ro] (ro == ec ? RS : " < ")
    while (reqs[package, ++ta])
      rtree(reqs[package, ta], ec)
    delete branch[ec--]
  }
  BEGIN {
    if (!getline xr < ARGV[2]) exit
    ARGC--
  }
  {
    if ($1 == "@")
      ya = $2
    if ($1 == "requires:") {
      for (zu = 2; zu <= NF; zu++) {
        reqs[$zu, ++ki[$zu]] = ya
      }
    }
  }
  END {
    rtree(xr)
  }
  ' setup.ini /tmp/tar.lst
}

_download() {
  while read b
  do download "$b"
  done < /tmp/tar.lst
}

download() {
  pkg=$1
  setwd

  awk '
  BEGIN {
    ARGC--
  }
  $1 == "@" && $2 == ARGV[2] {
    y = 1
  }
  $1 == "install:" && y {
    print $2, $4
    exit
  }
  ' setup.ini "$pkg" |
  while read nam ckm
  do

    drn=$(dirname "$nam")
    bsn=$(basename "$nam")

    mkdir -p "$lastcache"/"$elastmirror"/"$drn"
    cd "$lastcache"/"$elastmirror"/"$drn"
    if ! test -f "$bsn" || ! sha512sum -c <<eof
$ckm $bsn
eof
    then
      webreq "$lastmirror" "$drn"/"$bsn"
      sha512sum -c <<eof || return
$ckm $bsn
eof
    fi

    tar tf "$bsn" | gzip > /etc/setup/"$pkg".lst.gz
    cd "$lastcache"/"$elastmirror"/"$arch"
    echo "$drn" "$bsn" > /tmp/dwn
  done
}

_search() {
  if no_targets
  then return
  fi
  echo 'Searching downloaded packages...'
  for manifest in /etc/setup/*.lst.gz
  do
    if gzip -cd "$manifest" | grep -q -f /tmp/tar.lst
    then echo "$manifest"
    fi
  done | awk '$0=$4' FS='[./]'
}

resolve_deps() {
  setwd
  awk '
  function exists(file) {
    return getline < file < 0 ? 0 : 1
  }
  BEGIN {
    while (getline < ARGV[2]) ch[$NF]
    if (!$0) exit
    ARGC--
  }
  {
    if ($1 == "@")
      br = $2
    if ($1 == "install:" && br in ch) {
      delete ch[br]
      de = $2
      if (exists("../" de) && exists("/etc/setup/" br ".lst.gz"))
        next
      print br
    }
  }
  ' setup.ini "$1"
}

_searchall() {
  if ! read q < /tmp/tar.lst
  then return
  fi
  xr=$(mktemp /tmp/XXX)
  wget -O "$xr" -i - <<eof
https://cygwin.com/cgi-bin2/package-grep.cgi?text=1&arch=$arch&grep=$q
eof
  awk '
  BEGIN {
    FS = "-[[:digit:]]"
  }
  NR == 1 || z[$1]++ || /-debuginfo-/ || /^cygwin32-/ {
    next
  }
  {
    print $1
  }
  ' "$xr"
}

_install() {
  local pkg script
  j=$(mktemp)
  if [ "$nodeps" ]
  then cat /tmp/tar.lst
  else _depends
  fi |
  resolve_deps - |
  while read pkg
  do
    download "$pkg"
    read drn bsn < /tmp/dwn
    echo 'Unpacking...'
    tar -x -C / -f ../"$drn"/"$bsn"
    # update the package database

    awk '
    BEGIN {
      ARGC = 2
    }
    NR > 1 && ARGV[2] < $1 && !q {
      print ARGV[2], ARGV[3], 0
      q = 1
    }
    1
    END {
      if (!q) print ARGV[2], ARGV[3], 0
    }
    ' /etc/setup/installed.db "$pkg" "$bsn" > "$j"
    mv "$j" /etc/setup/installed.db

  done
  # run all postinstall scripts
  set /etc/postinstall/*.sh
  [ -e "$1" ] || shift
  for script do
    echo 'Running' "$script"
    "$script"
    mv "$script" "$script".done
  done
}

_remove() {
  cygcheck awk sh bunzip2 grep gzip mv sed tar xz > /tmp/rmv.lst
  while read q
  do

    if [ ! -f /etc/setup/"$q".lst.gz ]
    then
      echo "$q" 'package is not installed, skipping'
      continue
    fi
    gzip -dk /etc/setup/"$q".lst.gz
    if awk '
    BEGIN {
      FS = "[/\\\\]"
    }
    FILENAME == ARGV[1] {
      if ($NF) ess[$NF]
    }
    FILENAME == ARGV[2] {
      if ($NF in ess) exit 1
    }
    ' /tmp/rmv.lst /etc/setup/"$q".lst
    then
      echo 'Removing' "$q"
      if [ -f /etc/preremove/"$q".sh ]
      then
        /etc/preremove/"$q".sh
        rm /etc/preremove/"$q".sh
      fi
      while read each
      do
        if [ -f /"$each" ]
        then rm /"$each"
        fi
      done < /etc/setup/"$q".lst
      rm -f /etc/setup/"$q".lst.gz /etc/postinstall/"$q".sh.done
      awk '
      BEGIN {
        ARGC--
      }
      $1 != ARGV[2] {
        br = br ? br RS $0 : $0
      }
      END {
        print br > ARGV[1]
        print ARGV[2] " package removed"
      }
      ' /etc/setup/installed.db "$q"
    else
      echo 'cannot remove package' "$q"
      continue
    fi

  done < /tmp/tar.lst
  rm -f /etc/setup/*.lst
}

_autoremove() {
  setwd
  unset POSIXLY_CORRECT
  awk '
  NR == 1 {
    next
  }
  NR == FNR {
    score[$1] = $3 ? 0 : 1
    next
  }
  $1 == "@" {
    aph = $2
  }
  $1 == "category:" {
    if (/ Base/) {
      if (aph in score) {
        score[aph]++
      }
    }
  }
  $1 == "requires:" {
    for (z = 2; z <= NF; z++) {
      req[aph][$z]
    }
  }
  END {
    for (brv in req)
      if (brv in score) {
        for (cha in req[brv]) {
          score[cha]++
        }
      }
    while (!done) {
      done = 1
      for (det in score) {
        if (!score[det]) {
          done = 0
          print det
          delete score[det]
          if (isarray(req[det])) {
            for (ech in req[det]) {
              score[ech]--
            }
          }
        }
      }
    }
  }
  ' /etc/setup/installed.db setup.ini
}

_mirror() {
  awk '
  BEGIN {
    getline x < ARGV[2]
    ARGC--
  }
  {
    y = y ? y RS $0 : $0
  }
  /last-mirror/ {
    getline
    if (x)
      y = y "\n\t" x
    else {
      print $1
    }
  }
  END {
    if (x) {
      print y > ARGV[1]
      print "Mirror set to:\n" x
    }
  }
  ' /etc/setup/setup.rc /tmp/tar.lst
}

_cache() {
  awk '
  BEGIN {
    "cygpath -aiwf " ARGV[2] | getline x
    ARGC--
  }
  {
    z = z ? z RS $0 : $0
  }
  /last-cache/ {
    getline
    if (x)
      z = z "\n\t" x
    else {
      print $1
    }
  }
  END {
    if (x) {
      print z > ARGV[1]
      print "Cache set to:\n" x
    }
  }
  ' /etc/setup/setup.rc /tmp/tar.lst
}

> /tmp/tar.lst

# process options
until [ "$#" = 0 ]
do
  case $1 in

    --nodeps)
      nodeps=1
      shift
    ;;

    --version)
      echo 'Sage version 1.8.1'
      exit
    ;;

    cache | category | depends | download | install | list | listall | \
    listfiles | mirror | rdepends | remove | search | searchall | show | update)
      command=$1
      shift
    ;;

    *)
      echo "$1" >> /tmp/tar.lst
      shift
    ;;

  esac
done

if [ "$command" ]
then
  readonly arch=$(uname -m | sed s.i6.x.)
  _"$command"
else
  cat /usr/share/doc/sage/sage.txt
fi
