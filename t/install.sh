#!/bin/dash -e
. ./libsage.sh

q=/etc/setup/make.lst.gz
for y in /usr/local/http*/x86_64/release/make/make-*.tar.xz
do :
done

# rel=0 setup=0
xtrace rm -fv "$y" "$q"
xtrace sage install make
pause

# rel=0 setup=1
xtrace rm -fv "$y"
xtrace sage install make
pause

# rel=1 setup=0
xtrace rm -fv "$q"
xtrace sage install make
pause

# rel=1 setup=1
xtrace sage install make
