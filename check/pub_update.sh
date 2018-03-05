#!/bin/dash -e

# 0 0
rm -fv /usr/local/http*/x86_64/setup*
k-trace sage update

# 0 1
rm -fv /usr/local/http*/x86_64/setup.ini
k-trace sage update

# 1 0
rm -fv /usr/local/http*/x86_64/setup.bz2
k-trace sage update

# 1 1
k-trace sage update
