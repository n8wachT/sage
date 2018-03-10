#!/bin/dash -e
# -*- sh -*-

priv_download() {
  pkg=$1
  priv_setwd

  awk '
  BEGIN {
    ARGC--
  }
  $1 == "@" && $2 == ARGV[2] {
    y = 1
  }
  $1 == "install:" && y {
    print $4, $2
    exit
  }
  ' setup.ini "$pkg" > sha512.sum
  read digest path < sha512.sum
  mv sha512.sum ..
  cd ..
  if ! test -f "$path" || ! sha512sum -c sha512.sum
  then
    priv_webreq "$lastmirror" "$path"
    if ! sha512sum -c sha512.sum
    then
      return
    fi
  fi

  tar -tf "$path" | gzip > /etc/setup/"$pkg".lst.gz
}

priv_getwd() {
  velour '
  BEGIN {
    FS = "\t"
  }
  {
    if (/\t/) {
      x[y] = x[y] ? x[y] "," $2 : $2
    }
    else {
      sub("-", "")
      y = $0
    }
  }
  END {
    for (y in x) {
      print y "=" k_shellesc(x[y])
      print "e" y "=" k_shellesc(uri_encode(x[y]))
    }
  }
  ' /etc/setup/setup.rc > /etc/setup/setup.sh
}

priv_resolve_deps() {
  priv_setwd
  velour '
  BEGIN {
    while (getline < ARGV[2]) ch[$NF]
    if (!$0) {
      exit 1
    }
    ARGC--
  }
  {
    if ($1 == "@") {
      br = $2
    }
    if ($1 == "install:" && br in ch) {
      delete ch[br]
      de = $2
      if (io_exist("../" de) && io_exist("/etc/setup/" br ".lst.gz")) {
        next
      }
      print br
    }
  }
  ' setup.ini "$1"
}

priv_setwd() {
  if io-newer /etc/setup/setup.rc /etc/setup/setup.sh
  then
    priv_getwd
  fi
  . /etc/setup/setup.sh
  # need this when changing mirrors
  mkdir -p "$lastcache"/"$elastmirror"/"$arch"
  cd "$lastcache"/"$elastmirror"/"$arch"
}

priv_webreq() {
  install -D /dev/null "$2"
  if
    # if curl is not found, redirect stderr
    # if curl is found, redirect stdout
    curl -h >/dev/null 2>&1
  then
    curl -o "$2" "$1"/"$2"
  else
    printf '\33[1;33m%s\33[m\n' "$2"
    ftp -Av mirrors.sonic.net <<eof |
hash
binary
get cygwin/$2 $2
eof
    velour '
    BEGIN {
      RS = "#"
      FS = "[( ]"
    }
    NR == 1 {
      x = $(NF - 1) / (2048 * 100)
    }
    !n_modulo(NR, n_ceil(x)) {
      printf "%d%%\r", ++z
    }
    END {
      print ""
    }
    '
  fi
}

pub_autoremove() {
  priv_setwd
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
    for (brv in req) {
      if (brv in score) {
        for (cha in req[brv]) {
          score[cha]++
        }
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

pub_cache() {
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
    if (x) {
      z = z "\n\t" x
    }
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

pub_category() {
  priv_setwd
  awk '
  BEGIN {
    if (!getline b < ARGV[2]) {
      exit 1
    }
    ARGC--
  }
  {
    if ($1 == "@") {
      q = $2
    }
    if ($1 == "category:") {
      do {
        if ($NF == b) {
          print q
        }
      }
      while (--NF)
    }
  }
  ' setup.ini /tmp/tar.lst
}

pub_depends() {
  priv_setwd
  velour '
  function tree(package,   ec, ro, ta) {
    if (h_value(branch, package)) {
      return
    }
    branch[++ec] = package
    for (ro in branch) {
      printf branch[ro] (ro == ec ? RS : " > ")
    }
    while (reqs[package, ++ta]) {
      tree(reqs[package, ta], ec)
    }
    delete branch[ec--]
  }
  BEGIN {
    while (getline < ARGV[2]) xr[$0]
    if (!$0) {
      exit 1
    }
    ARGC--
  }
  {
    if ($1 == "@") {
      ya = $2
    }
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

pub_download() {
  while read x
  do
    priv_download "$x"
  done < /tmp/tar.lst
}

pub_install() {
  if [ "$nodeps" ]
  then
    cat /tmp/tar.lst
  else
    pub_depends
  fi |
  priv_resolve_deps - |
  while read fox
  do
    priv_download "$fox"
    echo 'Unpacking...'
    tar -x -C / -f "$path"

    # update the package database
    velour '
    BEGIN {
      ARGC = 2
    }
    NR == 1 {
      qu = $0
    }
    NR != 1 {
      ro[$1] = $2 FS $3
    }
    END {
      ro[ARGV[2]] = ARGV[3] FS 0
      for (xr in ro) {
        ya[++zu] = xr FS ro[xr]
      }
      a_sort(ya)
      for (xr in ya) {
        qu = qu RS ya[xr]
      }
      print qu > ARGV[1]
    }
    ' /etc/setup/installed.db "$fox" "$path"
  done

  # run all postinstall scripts
  set /etc/postinstall/*.sh
  [ -e "$1" ] || shift
  for nov do
    echo 'Running' "$nov"
    "$nov"
    mv "$nov" "$nov".done
  done
}

pub_list() {
  awk '
  BEGIN {
    getline q < ARGV[2]
    ARGC--
  }
  # q is already lower, so we dont need to touch it
  NR > 1 && tolower($1) ~ q {
    x = split($2, z, "/")
    print substr(z[x], 1, match(z[x], /\.[[:alpha:]]/) - 1)
  }
  ' /etc/setup/installed.db /tmp/tar.lst
}

pub_listall() {
  priv_setwd
  awk '
  BEGIN {
    if (!getline q < ARGV[2]) {
      exit 1
    }
    ARGC--
  }
  $1 == "@" && tolower($2) ~ tolower(q) {
    print $2
  }
  ' setup.ini /tmp/tar.lst
}

pub_listfiles() {
  if ! read x < /tmp/tar.lst
  then
    return
  fi
  priv_setwd
  find .. -name "$x"'-*' |
  awk '
  END {
    system("tar --list --file " $0)
  }
  '
}

pub_mirror() {
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
    if (x) {
      y = y "\n\t" x
    }
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

pub_rdepends() {
  priv_setwd
  velour '
  function rtree(package,   ec, ro, ta) {
    if (h_value(branch, package)) {
      return
    }
    branch[++ec] = package
    for (ro in branch) {
      printf branch[ro] (ro == ec ? RS : " < ")
    }
    while (reqs[package, ++ta]) {
      rtree(reqs[package, ta], ec)
    }
    delete branch[ec--]
  }
  BEGIN {
    if (!getline xr < ARGV[2]) {
      exit 1
    }
    ARGC--
  }
  {
    if ($1 == "@") {
      ya = $2
    }
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

pub_remove() {
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
      if ($NF) {
        ess[$NF]
      }
    }
    FILENAME == ARGV[2] {
      if ($NF in ess) {
        exit 1
      }
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
        then
          rm /"$each"
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

pub_search() {
  if [ ! -s /tmp/tar.lst ]
  then
    echo 'No packages found.'
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

pub_searchall() {
  if ! read q < /tmp/tar.lst
  then
    return
  fi
  curl -G -d text=1 -d arch="$arch" -d grep="$q" \
  https://cygwin.com/cgi-bin2/package-grep.cgi |
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
  '
}

pub_show() {
  priv_setwd
  awk '
  BEGIN {
    while (getline < ARGV[2]) x[$0]
    if (!$0) {
      exit 1
    }
    ARGC--
  }
  $1 == "@" {
    y = $2 in x
  }
  y
  ' setup.ini /tmp/tar.lst
}

pub_update() {
  # need this when changing mirrors
  priv_setwd
  cd ..
  priv_webreq "$lastmirror" "$arch"/setup.xz
  xzdec < "$arch"/setup.xz > "$arch"/setup.ini
  echo 'Updated setup.ini'
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

    version)
      echo 2.4.0
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
  pub_"$command"
else
  cat /usr/local/share/sage/readme.md
  exit 1
fi
