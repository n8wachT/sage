#!/bin/dash
pause() {
  echo 'Press any key to continue . . .'
  read _
  printf '\33c'
}

sage search
pause
sage search bin/wk
pause
sage search bin/awk
