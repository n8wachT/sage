#!/bin/dash
pause() {
  echo 'Press any key to continue . . .'
  read _
  printf '\033c'
}

sage search
pause
sage search bin/bsh
pause
sage search bin/bash
