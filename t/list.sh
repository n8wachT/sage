#!/bin/dash
pause() {
  echo 'Press any key to continue . . .'
  read _
  printf '\33c'
}

sage list
pause
sage list ^g
