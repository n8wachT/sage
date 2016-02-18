#!/bin/dash
pause() {
  echo 'Press any key to continue . . .'
  read _
  printf '\033c'
}

sage depends
pause
sage depends mak
pause
sage depends make
