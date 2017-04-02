#!/bin/dash -e
. ./libsage.sh
sh_trace sage rdepends
pause
sh_trace sage rdepends mak
pause
sh_trace sage rdepends make
