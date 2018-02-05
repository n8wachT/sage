#!/bin/dash -e

# 0 0
rm -fv /usr/local/http*/x86_64/setup*
sh-trace sage update

# 0 1
rm -fv /usr/local/http*/x86_64/setup.ini
sh-trace sage update

# 1 0
rm -fv /usr/local/http*/x86_64/setup.bz2
sh-trace sage update

# 1 1
sh-trace sage update
