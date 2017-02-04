# github.com/svnpenn/stdlib
. /usr/share/sh/libstd.sh

pause() {
  printf '\nPress Enter to continue...\n'
  read br
  printf '\33c'
}
