#!/bin/dash -e
ln -sfv "$PWD"/sage "$PWD"/sage-cost.sh "$PWD"/sage-date.awk \
  "$PWD"/sage-prune.sh "$PWD"/sage-spy.awk /usr/local/bin
mkdir -pv /usr/local/share/sage
ln -sfv "$PWD"/docs/readme.md /usr/local/share/sage
