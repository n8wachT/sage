#!/bin/dash
pause() {
  echo 'Press any key to continue . . .'
  read _
  printf '\33c'
}

sage remove
pause

sage remove mak
pause

# installed
sage install make
sage remove make
pause

# not installed
sage remove make
pause

# essential
sage remove xz
