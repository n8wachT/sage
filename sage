#!/bin/dash
#-*-mode:sh-*-
usage="\
NAME
  Sage - package manager utility

SYNOPSIS
  sage [operation] [options] [targets]

DESCRIPTION
  Sage is a package management utility that tracks installed packages on a
  Cygwin system. Invoking Sage involves specifying an operation with any
  potential options and targets to operate on. A target is usually a package
  name, file name, URL, or a search string. Targets can be provided as command
  line arguments.

OPERATIONS
  install
    Install package(s).

  remove
    Remove package(s) from the system.

  update
    Download a fresh copy of the master package list (setup.ini) from the
    server defined in setup.rc.

  download
    Retrieve package(s) from the server, but do not install/upgrade anything.

  show
    Display information on given package(s).

  depends
    Produce a dependency tree for a package.

  rdepends
    Produce a tree of packages that depend on the named package.

  list
    Search each locally-installed package for names that match regexp. If no
    package names are provided in the command line, all installed packages will
    be queried.

  listall
    This will search each package in the master package list (setup.ini) for
    names that match regexp.

  category
    Display all packages that are members of a named category.

  listfiles
    List all files owned by a given package. Multiple packages can be specified
    on the command line.

  search
    Search for downloaded packages that own the specified file(s). The path can
    be relative or absolute, and one or more files can be specified.

  searchall
    Search cygwin.com to retrieve file information about packages. The provided
    target is considered to be a filename and searchall will return the
    package(s) which contain this file.

  mirror
    Set the mirror; a full URL to a location where the database, packages, and
    signatures for this repository can be found. If no URL is provided, display
    current mirror.

  cache
    Set the package cache directory. If a file is not found in cache directory,
    it will be downloaded. Unix and Windows forms are accepted, as well as
    absolute or regular paths. If no directory is provided, display current
    cache.

OPTIONS
  --nodeps
    Specify this option to skip all dependency checks.

  --version
    Display version and exit.
"

wget() {
  if command wget -h 2>&1 >/dev/null
  then
    command wget "$@"
  else
    warn wget is not installed, using lynx as fallback
    set "${*: -1}"
    lynx -source "$1" > "${1##*/}"
  fi
}

find_workspace() {
  # default working directory and mirror
  
  # work wherever setup worked last, if possible
  cache=$(awk '
  BEGIN {
    RS = "\n\\<"
    FS = "\n\t"
  }
  $1 == "last-cache" {
    print $2
  }
  ' /etc/setup/setup.rc | cygpath -f-)

  mirror=$(awk '
  /last-mirror/ {
    getline
    print $1
  }
  ' /etc/setup/setup.rc)
  mirrordir=$(echo "$mirror" | sed 's./.%2f.g; s.:.%3a.g')

  mkdir -p "$cache/$mirrordir/$arch"
  cd "$cache/$mirrordir/$arch"
  if [ -e setup.ini ]
  then
    return 0
  else
    get_setup
    return 1
  fi
}

get_setup() {
  touch setup.ini
  mv setup.ini setup.ini-save
  wget -N $mirror/$arch/setup.bz2
  if [ -e setup.bz2 ]
  then
    bunzip2 setup.bz2
    mv setup setup.ini
    echo Updated setup.ini
  else
    echo Error updating setup.ini, reverting
    mv setup.ini-save setup.ini
  fi
}

no_targets() {
  if [ -s /etc/setup/targets.db ]
  then
    return 1
  else
    echo No packages found.
    return 0
  fi
}

warn() {
  printf '\033[1;31m%s\033[m\n' "$*" >&2
}

_update() {
  if find_workspace
  then
    get_setup
  fi
}

_category() {
  if no_targets
  then
    return
  fi
  find_workspace
  awk '
  FILENAME ~ ARGV[1] {
    query = $0
  }
  FILENAME ~ ARGV[2] {
    if ($1 == "@")
      pck = $2
    if ($1 == "category:" && $0 ~ query)
      print pck
  }
  ' /etc/setup/targets.db setup.ini
}

_list() {
  awk '
  FILENAME ~ ARGV[1] {
    pkg = $0
  }
  FILENAME ~ ARGV[2] && FNR > 1 && $1 ~ pkg {
    print $1
  }
  ' /etc/setup/targets.db /etc/setup/installed.db
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
  FILENAME ~ ARGV[1] {
    pkg = $1
  }
  FILENAME ~ ARGV[2] && $1 ~ pkg {
    print $1
  }
  ' /etc/setup/targets.db setup.ini
}

_listfiles() {
  if no_targets
  then
    return
  fi
  find_workspace
  read pkg </etc/setup/targets.db
  if [ ! -e /etc/setup/$pkg.lst.gz ]
  then
    download $pkg
  fi
  gzip -cd /etc/setup/$pkg.lst.gz
}

_show() {
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
  FILENAME ~ ARGV[1] {
    query = $1
  }
  FILENAME ~ ARGV[2] && $1 == query {
    print
    fd++
  }
  END {
    if (! fd)
      print "Unable to locate package " query
  }
  ' /etc/setup/targets.db setup.ini
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
  function prpg(fpg) {
    if (smartmatch(fpg, spath))
      return
    spath[++x] = fpg
    for (y in spath)
      printf spath[y] (y==x ? RS : " > ")
    if (reqs[fpg][1])
      for (each in reqs[fpg])
        prpg(reqs[fpg][each])
    delete spath[x--]
  }
  FILENAME ~ ARGV[1] {
    z[$0]
  }
  FILENAME ~ ARGV[2] {
    if ($1 == "@")
      apg = $2
    if ($1 == "requires:")
      for (y=2; y<=NF; y++)
        reqs[apg][y-1] = $y
  }
  END {
    for (y in z)
      prpg(y)
  }
  ' /etc/setup/targets.db setup.ini
}

_rdepends() {
  if no_targets
  then
    return
  fi
  find_workspace
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
  FILENAME ~ ARGV[1] {
    li = $0
  }
  FILENAME ~ ARGV[2] {
    if ($1 == "@")
      apg = $2
    if ($1 == "requires:")
      for (mi=2; mi<=NF; mi++)
        reqs[$mi][++no[$mi]] = apg
  }
  END {
    prpg(li)
  }
  ' /etc/setup/targets.db setup.ini
}

_download() {
  if no_targets
  then
    return
  fi
  find_workspace
  read pkg </etc/setup/targets.db
  download "$pkg"
}

download() {
  local pkg digest digactual
  pkg=$1
  # look for package and save desc file

  awk '$1 == pc' RS='\n\n@ ' FS='\n' pc=$pkg setup.ini > desc
  if [ ! -s desc ]
  then
    echo Unable to locate package $pkg
    exit 1
  fi

  # download and unpack the bz2 or xz file

  # pick the latest version, which comes first
  set -- $(awk '$1 == "install:"' desc)
  if [ $# = 0 ]
  then
    echo 'Could not find "install" in package description: obsolete package?'
    exit 1
  fi

  dn=$(dirname $2)
  bn=$(basename $2)

  # check the md5
  digest=$4
  case ${#digest} in
   32) hash=md5sum    ;;
  128) hash=sha512sum ;;
  esac
  mkdir -p "$cache/$mirrordir/$dn"
  cd "$cache/$mirrordir/$dn"
  if ! test -e $bn || ! echo "$digest $bn" | $hash -c
  then
    wget -O $bn $mirror/$dn/$bn
    echo "$digest $bn" | $hash -c || exit
  fi

  tar tf $bn | gzip > /etc/setup/"$pkg".lst.gz
  cd "$OLDPWD"
  echo $dn $bn > /tmp/dwn
}

_search() {
  if no_targets
  then
    return
  fi
  echo Searching downloaded packages...
  for manifest in /etc/setup/*.lst.gz
  do
    if gzip -cd $manifest | grep -q -f /etc/setup/targets.db
    then
      echo $manifest
    fi
  done | awk '$0=$4' FS='[./]'
}

_searchall() {
  if no_targets
  then
    return
  fi
  read pks </etc/setup/targets.db
  wget -O /tmp/matches \
    'cygwin.com/cgi-bin2/package-grep.cgi?text=1&arch='$arch'&grep='$pks
  awk '
  NR == 1 {next}
  mc[$1]++ {next}
  /-debuginfo-/ {next}
  /^cygwin32-/ {next}
  {print $1}
  ' FS=-[[:digit:]] /tmp/matches
}

_install() {
  if no_targets
  then
    return
  fi
  find_workspace
  local pkg dn bn script
  if [ $nodeps ]
  then
    cat /etc/setup/targets.db
  else
    _depends
  fi |
  awk '
  function e(file) {
    return getline < file < 0 ? 0 : 1
  }
  FILENAME == ARGV[1] {
    ch[$NF]
  }
  FILENAME == ARGV[2] {
    if ($1 == "@") {
      br = $2
    }
    if ($1 == "install:" && br in ch) {
      delete ch[br]
      de = $2
      if (e("../" de) && e("/etc/setup/" br ".lst.gz"))
        next
      print br
    }
  }
  ' - setup.ini |
  while read pkg
  do
  echo Installing $pkg
  download $pkg
  read dn bn </tmp/dwn
  echo Unpacking...
  tar -x -C / -f "$cache/$mirrordir/$dn/$bn"
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
  ' pkg="$pkg" bz=$bn /etc/setup/installed.db > /tmp/awk.$$
  mv /etc/setup/installed.db /etc/setup/installed.db-save
  mv /tmp/awk.$$ /etc/setup/installed.db

  done
  # run all postinstall scripts
  find /etc/postinstall -name '*.sh' | while read script
  do
    echo Running $script
    $script
    mv $script $script.done
  done
}

_remove() {
  if no_targets
  then
    return
  fi
  cd /etc
  cygcheck awk bash bunzip2 grep gzip mv sed tar xz > setup/essential.lst
  while read pkg
  do

  if ! grep -q "^$pkg " setup/installed.db
  then
    echo Package $pkg is not installed, skipping
    continue
  fi

  if [ ! -e setup/"$pkg".lst.gz ]
  then
    warn Package manifest missing, cannot remove $pkg. Exiting
    exit 1
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
  ' FS='[/\\\\]' setup/*.lst
  esn=$?
  if [ $esn = 0 ]
  then
    echo Removing $pkg
    if [ -e preremove/"$pkg".sh ]
    then
      preremove/"$pkg".sh
      rm preremove/"$pkg".sh
    fi
    while read each
    do
      if [ -f /$each ]
      then
        rm /$each
      fi
    done < setup/"$pkg".lst
    rm -f setup/"$pkg".lst.gz postinstall/"$pkg".sh.done
    awk -i inplace '$1 != ENVIRON["pkg"]' setup/installed.db
    echo Package $pkg removed
  fi
  rm setup/"$pkg".lst
  if [ $esn = 1 ]
  then
    warn Sage cannot remove package $pkg, exiting
    exit 1
  fi

  done </etc/setup/targets.db
}

_autoremove() {
  find-workspace
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
  if [ -s /etc/setup/targets.db ]
  then
    awk '
    FILENAME ~ ARGV[1] {
      pks = $0
    }
    FILENAME ~ ARGV[2] {
      print
      if (/last-mirror/) {
        getline
        print "\t" pks
      }
    }
    ' /etc/setup/targets.db /etc/setup/setup.rc > /tmp/setup.rc
    mv /tmp/setup.rc /etc/setup/setup.rc
    sed 'iMirror set to' /etc/setup/targets.db
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
  if [ -s /etc/setup/targets.db ]
  then
    ya=$(cygpath -awf /etc/setup/targets.db | sed 's \\ \\\\ g')
    awk '
    1
    /last-cache/ {
      getline
      print "\t" ya
    }
    ' ya="$ya" /etc/setup/setup.rc > /tmp/setup.rc
    mv /tmp/setup.rc /etc/setup/setup.rc
    echo "Cache set to $ya"
  else
    awk '
    /last-cache/ {
      getline
      print $1
    }
    ' /etc/setup/setup.rc
  fi
}

> /etc/setup/targets.db

# process options
until [ $# = 0 ]
do
  case "$1" in

    --nodeps)
      nodeps=1
      shift
    ;;

    --version)
      echo 'Sage version 1.3.0'
      exit
    ;;

    update)
      command=$1
      shift
    ;;

    list | cache  | remove | depends | listall  | download | listfiles |\
    show | mirror | search | install | category | rdepends | searchall )
      command=$1
      shift
    ;;

    *)
      echo "$1" >> /etc/setup/targets.db
      shift
    ;;

  esac
done

set -a

if [ "$command" ]
then
  readonly arch=$(arch | sed s.i6.x.)
  _"$command"
else
  printf "$usage"
fi
