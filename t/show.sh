#!/bin/dash
pause() {
  echo 'Press any key to continue . . .'
  read _
  printf '\033c'
}

sage show
pause
sage show mak
pause
sage show make
