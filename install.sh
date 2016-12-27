#!/bin/dash -e
ln -sfv "$PWD"/sage "$PWD"/sage-cost.sh "$PWD"/sage-prune.sh \
  "$PWD"/sage-spy.sh /usr/local/bin
mkdir -pv /usr/share/doc/sage
ln -sfv "$PWD"/sage.txt /usr/share/doc/sage
