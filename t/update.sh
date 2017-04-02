#!/bin/dash -e
. ./libsage.sh

# 0 0
rm -fv /usr/local/http*/x86_64/setup*
sh_trace sage update

# 0 1
rm -fv /usr/local/http*/x86_64/setup.ini
sh_trace sage update

# 1 0
rm -fv /usr/local/http*/x86_64/setup.bz2
sh_trace sage update

# 1 1
sh_trace sage update
