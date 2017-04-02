#!/bin/dash -e
. ./libsage.sh

sh_trace sage remove

sh_trace sage remove mak

# installed
sh_trace sage install make
sh_trace sage remove make

# not installed
sh_trace sage remove make

# essential
sh_trace sage remove xz
