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
  function encodeURIComponent(str,   start, j) {
    for (i = 0; i <= 255; i++)
      charCodeAt[sprintf("%c", i)] = i
    while (i = substr(str, ++start, 1))
      if (i ~ /[[:alnum:]_.~-]/)
        j = j i
      else
        j = j "%" sprintf("%02X", charCodeAt[i])
    return j
  }
  $1 == "last-cache" {
    getline
    y = $1
  }
  $1 == "last-mirror" {
    getline
    z = $1
  }
  END {
    print z
    print y "/" encodeURIComponent(z)
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
    if ($1 == "category:")
      do
        if ($NF == query)
          print pck
      while (--NF)
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
  BEGIN {
    RS = "\n\n@ "
    FS = "\n"
  }
  FILENAME == ARGV[1] {
    pkg = $1
  }
  FILENAME == ARGV[2] && $1 ~ pkg {
    print $1
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
function smartmatch(small, large,    values) {
  for (each in large)
    values[large[each]]
  return small in values
}
'

_depends() {
  if no_targets
  then
    return
  fi
  find_workspace
  awk "$smartmatch"'
  function prpg(fpg, each) {
    if (smartmatch(fpg, spath))
      return
    spath[++x] = fpg
    for (y in spath)
      printf spath[y] (y==x ? RS : " > ")
    while (reqs[fpg, ++each])
      prpg(reqs[fpg, each])
    delete spath[x--]
  }
  FILENAME == ARGV[1] {
    z[$0]
  }
  FILENAME == ARGV[2] {
    if ($1 == "@")
      apg = $2
    if ($1 == "requires:")
      for (y=2; y<=NF; y++)
        reqs[apg, y-1] = $y
  }
  END {
    for (y in z)
      prpg(y)
  }
  ' /tmp/tar.lst setup.ini
}

_rdepends() {
  if no_targets
  then
    return
  fi
  find_workspace
  unset POSIXLY_CORRECT
  awk "$smartmatch"'
  function prpg(fpg) {
    if (smartmatch(fpg, spath))
      return
    spath[++ju] = fpg
    for (ki in spath)
      printf spath[ki] (ki==ju ? RS : " < ")
    if (reqs[fpg][1])
      for (each in reqs[fpg])
        prpg(reqs[fpg][each])
    delete spath[ju--]
  }
  FILENAME == ARGV[1] {
    li = $0
  }
  FILENAME == ARGV[2] {
    if ($1 == "@")
      apg = $2
    if ($1 == "requires:")
      for (mi=2; mi<=NF; mi++)
        reqs[$mi][++no[$mi]] = apg
  }
  END {
    prpg(li)
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
  local pkg digest digactual
  pkg=$1
  # look for package and save desc file

  awk '$1 == pc' RS='\n\n@ ' FS='\n' pc="$pkg" setup.ini > desc
  if [ ! -s desc ]
  then
    echo 'Unable to locate package' "$pkg"
    return
  fi

  # download and unpack the bz2 or xz file

  # pick the latest version, which comes first
  set -- $(awk '$1 == "install:"' desc)
  if [ "$#" = 0 ]
  then
    echo 'Could not find "install" in package description: obsolete package?'
    return
  fi

  dn=$(dirname "$2")
  bn=$(basename "$2")

  # check the md5
  digest=$4
  case ${#digest} in
   32) hash=md5sum    ;;
  128) hash=sha512sum ;;
  esac
  mkdir -p "$cache"/"$dn"
  cd "$cache"/"$dn"
  if ! test -f "$bn" || ! echo "$digest" "$bn" | "$hash" -c
  then
    wget -O "$bn" "$mirror"/"$dn"/"$bn"
    echo "$digest" "$bn" | "$hash" -c || return
  fi

  tar tf "$bn" | gzip > /etc/setup/"$pkg".lst.gz
  cd "$cache"/"$arch"
  echo "$dn" "$bn" > /tmp/dwn
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
  xr=$(mktemp)
  while read pks
  do
    wget -O "$xr" \
    'cygwin.com/cgi-bin2/package-grep.cgi?text=1&arch='"$arch"'&grep='"$pks"
    awk '
    NR == 1 {next}
    mc[$1]++ {next}
    /-debuginfo-/ {next}
    /^cygwin32-/ {next}
    {print $1}
    ' FS=-[[:digit:]] "$xr"
  done </tmp/tar.lst
}

_install() {
  if no_targets
  then
    return
  fi
  find_workspace
  local pkg dn bn script
  if [ "$nodeps" ]
  then
    cat /tmp/tar.lst
  else
    _depends
  fi |
  resolve_deps - |
  while read pkg
  do
    echo 'Installing' "$pkg"
    download "$pkg"
    read dn bn </tmp/dwn
    echo 'Unpacking...'
    tar -x -C / -f ../"$dn"/"$bn"
    # update the package database

    awk '
    ins != 1 && pkg < $1 {
      print pkg, bz, 0
      ins = 1
    }
    1
    END {
      if (ins != 1) print pkg, bz, 0
    }
    ' pkg="$pkg" bz="$bn" /etc/setup/installed.db > /tmp/installed.db
    mv /tmp/installed.db /etc/setup/installed.db

  done
  # run all postinstall scripts
  find /etc/postinstall -name '*.sh' | while read script
  do
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
  cygcheck awk bash bunzip2 grep gzip mv sed tar xz > /tmp/rmv.lst
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
      BEGIN {ARGC--}
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
    if (/ Base/)
      if (aph in score)
        score[aph]++
  }
  $1 == "requires:" {
    for (z=2; z<=NF; z++)
      req[aph][$z]
  }
  END {
    for (brv in req)
      if (brv in score)
        for (cha in req[brv])
          score[cha]++
    while (! done) {
      done=1
      for (det in score)
        if (! score[det]) {
          done=0
          print det
          delete score[det]
          if (isarray(req[det]))
            for (ech in req[det])
              score[ech]--
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
