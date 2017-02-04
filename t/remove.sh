#!/bin/dash -e
. ./libsage.sh

xtrace sage remove

xtrace sage remove mak

# installed
xtrace sage install make
xtrace sage remove make

# not installed
xtrace sage remove make

# essential
xtrace sage remove xz
