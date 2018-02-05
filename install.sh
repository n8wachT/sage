#!/bin/dash -e
ln -sfv "$PWD"/sage /usr/local/bin

cd doc
mkdir -pv /usr/local/share/sage
ln -sfv "$PWD"/readme.md /usr/local/share/sage

cd ../contrib
{
  printf '%s\n' *.sh *.awk
  basename -s .sh *.sh
  basename -s .awk *.awk
} |
pr -2t |
while read q x
do
  ln -sfv "$PWD"/"$q" /usr/local/bin/"$x"
done
