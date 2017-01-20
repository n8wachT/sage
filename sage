#!/bin/dash -e
# -*- sh -*-

wget() {
  if command wget -h 2>&1 >/dev/null
  then
    command wget "$@"
  else
    echo 'wget is not installed, using lynx as fallback'
    set "${*: -1}"
    lynx -source "$1" > "${1##*/}"
  fi
}

find_workspace() {
  awk '
  function encodeURIComponent(str,   j, q, y, z) {
    while (j++ < 125) q[sprintf("%c", j)] = j
    while (j = substr(str, ++y, 1))
      z = j ~ /[[:alnum:]_.!~*\47()-]/ ? z j : z sprintf("%%%02X", q[j])
    return z
  }
  $1 == "last-cache" {
    getline
    k = $1
  }
  $1 == "last-mirror" {
    getline
    v = $1
  }
  END {
    print v
    print k "/" encodeURIComponent(v)
  }
  ' /etc/setup/setup.rc > /tmp/fin.lst
  for each in mirror cache
  do
    read -r "$each"
  done < /tmp/fin.lst
  cd "$cache"/"$arch"
}

no_targets() {
  if [ -s /tmp/tar.lst ]
  then
    false
  else
    echo 'No packages found.'
  fi
}

_update() {
  find_workspace
  wget -N "$mirror"/"$arch"/setup.bz2
  bunzip2 < setup.bz2 > setup.ini
  echo 'Updated setup.ini'
}

_category() {
  if no_targets
  then
    return
  fi
  find_workspace
  awk '
  FILENAME == ARGV[1] {
    query = $0
  }
  FILENAME == ARGV[2] {
    if ($1 == "@")
      pck = $2
    if ($1 == "category:") {
      do
        if ($NF == query) {
          print pck
        }
      while (--NF)
    }
  }
  ' /tmp/tar.lst setup.ini
}

_list() {
  awk '
  FILENAME == ARGV[1] {
    pkg = $0
  }
  FILENAME == ARGV[2] && FNR > 1 && $1 ~ pkg {
    print $1
  }
  ' /tmp/tar.lst /etc/setup/installed.db
}

_listall() {
  if no_targets
  then
    return
  fi
  find_workspace
  awk '
  FILENAME == ARGV[1] {
    pkg = $0
  }
  FILENAME == ARGV[2] && $1 == "@" && $2 ~ pkg {
    print $2
  }
  ' /tmp/tar.lst setup.ini
}

_listfiles() {
  if no_targets
  then
    return
  fi
  find_workspace
  while read pkg
  do
    if [ ! -f /etc/setup/"$pkg".lst.gz ]
    then
      download "$pkg"
    fi
    gzip -cd /etc/setup/"$pkg".lst.gz
  done </tmp/tar.lst
}

_show() {
  find_workspace
  awk '
  FILENAME == ARGV[1] {
    x[$0]
  }
  FILENAME == ARGV[2] && $1 == "@" {
    y = $2 in x ? 1 : 0
  }
  y
  ' /tmp/tar.lst setup.ini
}

smartmatch='
function smartmatch(diamond, rough,   x, y) {
  for (x in rough) y[rough[x]]
  return diamond in y
}
'

_depends() {
  if no_targets
  then
    return
  fi
  find_workspace
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
  FILENAME == ARGV[1] {
    xr[$0]
  }
  FILENAME == ARGV[2] {
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
  ' /tmp/tar.lst setup.ini
}

_rdepends() {
  if no_targets
  then
    return
  fi
  find_workspace
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
  FILENAME == ARGV[1] {
    xr = $0
  }
  FILENAME == ARGV[2] {
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
  ' /tmp/tar.lst setup.ini
}

_download() {
  if no_targets
  then
    return
  fi
  find_workspace
  while read pkg
  do
    download "$pkg"
  done </tmp/tar.lst
}

download() {
  pkg=$1

  awk '
  BEGIN {
    ARGC = 2
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

    mkdir -p "$cache"/"$drn"
    cd "$cache"/"$drn"
    if ! test -f "$bsn" || ! sha512sum -c <<eof
$ckm $bsn
eof
    then
      wget -O "$bsn" "$mirror"/"$drn"/"$bsn"
      sha512sum -c <<eof || return
$ckm $bsn
eof
    fi

    tar tf "$bsn" | gzip > /etc/setup/"$pkg".lst.gz
    cd "$cache"/"$arch"
    echo "$drn" "$bsn" > /tmp/dwn
  done
}

_search() {
  if no_targets
  then
    return
  fi
  echo 'Searching downloaded packages...'
  for manifest in /etc/setup/*.lst.gz
  do
    if gzip -cd "$manifest" | grep -q -f /tmp/tar.lst
    then
      echo "$manifest"
    fi
  done | awk '$0=$4' FS='[./]'
}

resolve_deps() {
  awk '
  function e(file) {
    return getline < file < 0 ? 0 : 1
  }
  FILENAME == ARGV[1] {
    ch[$NF]
  }
  FILENAME == ARGV[2] {
    if ($1 == "@")
      br = $2
    if ($1 == "install:" && br in ch) {
      delete ch[br]
      de = $2
      if (e("../" de) && e("/etc/setup/" br ".lst.gz"))
        next
      print br
    }
  }
  ' "$1" setup.ini
}

_searchall() {
  if no_targets
  then
    return
  fi
  xr=$(mktemp /tmp/XXX)
  read v </tmp/tar.lst
  wget -O "$xr" \
  'https://cygwin.com/cgi-bin2/package-grep.cgi?text=1&arch='"$arch"'&grep='"$v"
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
  if no_targets
  then
    return
  fi
  find_workspace
  local pkg script
  j=$(mktemp)
  if [ "$nodeps" ]
  then
    cat /tmp/tar.lst
  else
    _depends
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
  if no_targets
  then
    return
  fi
  cd /etc
  cygcheck awk sh bunzip2 grep gzip mv sed tar xz > /tmp/rmv.lst
  while read pkg
  do

    if [ ! -f setup/"$pkg".lst.gz ]
    then
      echo "$pkg" 'package is not installed, skipping'
      continue
    fi
    gzip -dk setup/"$pkg".lst.gz
    awk '
    NR == FNR {
      if ($NF) ess[$NF]
      next
    }
    $NF in ess {
      exit 1
    }
    ' FS='[/\\\\]' /tmp/rmv.lst setup/"$pkg".lst
    esn=$?
    if [ "$esn" = 0 ]
    then
      echo 'Removing' "$pkg"
      if [ -f preremove/"$pkg".sh ]
      then
        preremove/"$pkg".sh
        rm preremove/"$pkg".sh
      fi
      while read each
      do
        if [ -f /"$each" ]
        then
          rm /"$each"
        fi
      done < setup/"$pkg".lst
      rm -f setup/"$pkg".lst.gz postinstall/"$pkg".sh.done
      awk '
      BEGIN {ARGC = 2}
      $1 != ARGV[2]
      ' setup/installed.db "$pkg" > /tmp/installed.db
      mv /tmp/installed.db setup/installed.db
      echo "$pkg" 'package removed'
    fi
    rm setup/"$pkg".lst
    if [ "$esn" = 1 ]
    then
      echo 'cannot remove package' "$pkg"
      continue
    fi

  done </tmp/tar.lst
}

_autoremove() {
  find-workspace
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
  ' /etc/setup/installed.db setup.ini | sage remove
}

_mirror() {
  if [ -s /tmp/tar.lst ]
  then
    awk '
    FILENAME == ARGV[1] {
      pks = $0
    }
    FILENAME == ARGV[2] {
      print
      if (/last-mirror/) {
        getline
        print "\t" pks
      }
    }
    ' /tmp/tar.lst /etc/setup/setup.rc > /tmp/setup.rc
    mv /tmp/setup.rc /etc/setup/setup.rc
    sed 'iMirror set to' /tmp/tar.lst
  else
    awk '
    /last-mirror/ {
      getline
      print $1
    }
    ' /etc/setup/setup.rc
  fi
}

_cache() {
  if [ -s /tmp/tar.lst ]
  then
    ya=$(cygpath -aiwf /tmp/tar.lst | sed 's \\ \\\\ g')
    awk '
    1
    /last-cache/ {
      getline
      print "\t" ya
    }
    ' ya="$ya" /etc/setup/setup.rc > /tmp/setup.rc
    mv /tmp/setup.rc /etc/setup/setup.rc
    echo 'Cache set to' "$ya"
  else
    awk '
    /last-cache/ {
      getline
      print $1
    }
    ' /etc/setup/setup.rc
  fi
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
      echo 'Sage version 1.7.0'
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
