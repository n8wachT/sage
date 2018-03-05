#!/bin/dash
# dont use -e, we are expecting some of these to fail
for q in /usr/local/http*/x86_64/release/make/make-*.tar.xz
do
  :
done
k-trace sage download

k-trace sage download mak

# exist=0
k-trace rm -fv "$q"
k-trace sage download make

# exist=1 sha=0
k-trace dd if=/dev/null of="$q"
k-trace sage download make

# exist=1 sha=1
k-trace sage download make
