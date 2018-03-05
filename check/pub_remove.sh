#!/bin/dash -e
k-trace sage remove
k-trace sage remove mak

# installed
k-trace sage install make
k-trace sage remove make

# not installed
k-trace sage remove make

# essential
k-trace sage remove xz
