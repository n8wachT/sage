#!/bin/dash
pause() {
  echo 'Press any key to continue . . .'
  read _
  printf '\33c'
}

sage searchall
pause
sage searchall usr/bin/awj
pause
sage searchall usr/bin/awk
