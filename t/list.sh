#!/bin/dash -e
. ./libsage.sh
sh_trace sage list
pause
sh_trace sage list ^g
