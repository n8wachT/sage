#!/bin/dash
pause() {
  echo 'Press any key to continue . . .'
  read _
  printf '\33c'
}

sage rdepends
pause
sage rdepends mak
pause
sage rdepends make
