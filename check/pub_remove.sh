#!/bin/dash -e
sh-trace sage remove
sh-trace sage remove mak

# installed
sh-trace sage install make
sh-trace sage remove make

# not installed
sh-trace sage remove make

# essential
sh-trace sage remove xz
