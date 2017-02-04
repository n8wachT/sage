#!/bin/dash -e
. ./libsage.sh

# 0 0
rm -fv /usr/local/http*/x86_64/setup*
xtrace sage update

# 0 1
rm -fv /usr/local/http*/x86_64/setup.ini
xtrace sage update

# 1 0
rm -fv /usr/local/http*/x86_64/setup.bz2
xtrace sage update

# 1 1
xtrace sage update
