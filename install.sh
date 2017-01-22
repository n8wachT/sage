#!/bin/dash -e
ln -sfv "$PWD"/sage "$PWD"/sage-cost.sh "$PWD"/sage-date.awk \
  "$PWD"/sage-prune.sh "$PWD"/sage-spy.awk /usr/local/bin
mkdir -pv /usr/share/doc/sage
ln -sfv "$PWD"/sage.txt /usr/share/doc/sage
