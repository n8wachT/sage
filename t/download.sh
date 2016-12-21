#!/bin/dash
rel=/Documents/http*/x86_64/release/make/make-4.1-1.tar.xz

pause() {
  echo 'Press any key to continue . . .'
  read _
  printf '\33c'
}

sage download
pause

sage download mak
pause

# exist=0
rm -f $rel
sage download make
pause

# exist=1 sha=0
truncate -s0 $rel
sage download make
pause

# exist=1 sha=1
sage download make
