#!/bin/dash
# dont use -e, we are expecting some of these to fail
. ./libsage.sh

for q in /usr/local/http*/x86_64/release/make/make-*.tar.xz
do :
done
sh_trace sage download

sh_trace sage download mak

# exist=0
sh_trace rm -fv "$q"
sh_trace sage download make

# exist=1 sha=0
sh_trace dd if=/dev/null of="$q"
sh_trace sage download make

# exist=1 sha=1
sh_trace sage download make
