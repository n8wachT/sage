#!/bin/dash -e
. ./libsage.sh
sh_trace sage depends
pause
sh_trace sage depends mak
pause
sh_trace sage depends make
