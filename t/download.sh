#!/bin/dash
# dont use -e, we are expecting some of these to fail
. ./libsage.sh

for q in /usr/local/http*/x86_64/release/make/make-*.tar.xz
do :
done
xtrace sage download

xtrace sage download mak

# exist=0
xtrace rm -fv "$q"
xtrace sage download make

# exist=1 sha=0
xtrace dd if=/dev/null of="$q"
xtrace sage download make

# exist=1 sha=1
xtrace sage download make
