#!/bin/dash -e
q=/etc/setup/make.lst.gz
for y in /usr/local/http*/x86_64/release/make/make-*.tar.xz
do
  :
done

# rel=0 setup=0
sh-trace rm -fv "$y" "$q"
sh-trace sage install make
./pause

# rel=0 setup=1
sh-trace rm -fv "$y"
sh-trace sage install make
./pause

# rel=1 setup=0
sh-trace rm -fv "$q"
sh-trace sage install make
./pause

# rel=1 setup=1
sh-trace sage install make
