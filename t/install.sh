#!/bin/dash
rel=/Documents/http*/x86_64/release/make/make-4.1-1.tar.xz
setup=/etc/setup/make.lst.gz

pause() {
  echo 'Press any key to continue . . .'
  read _
  printf '\033c'
}

# rel=0 setup=0
rm $rel $setup
sage install make
pause

# rel=0 setup=1
rm $rel
sage install make
pause

# rel=1 setup=0
rm $setup
sage install make
pause

# rel=1 setup=1
sage install make
