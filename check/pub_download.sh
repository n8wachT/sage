#!/bin/dash
# dont use -e, we are expecting some of these to fail
for q in /usr/local/http*/x86_64/release/make/make-*.tar.xz
do
  :
done
sh-trace sage download

sh-trace sage download mak

# exist=0
sh-trace rm -fv "$q"
sh-trace sage download make

# exist=1 sha=0
sh-trace dd if=/dev/null of="$q"
sh-trace sage download make

# exist=1 sha=1
sh-trace sage download make
