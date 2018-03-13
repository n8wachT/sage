#!/bin/dash -e
q=/etc/setup/make.lst.gz
for y in /usr/local/http*/x86_64/release/make/make-*.tar.xz
do
  :
done

# rel=0 setup=0
k-trace rm -fv "$y" "$q"
k-trace sage install make
./pause

# rel=0 setup=1
k-trace rm -fv "$y"
k-trace sage install make
./pause

# rel=1 setup=0
k-trace rm -fv "$q"
k-trace sage install make
./pause

# rel=1 setup=1
k-trace sage install make
