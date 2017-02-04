#!/bin/dash
. stdlib.sh

pause() {
  printf '\nPress Enter to continue...\n'
  read br
  printf '\33c'
}
