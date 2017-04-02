#!/bin/dash -e
. ./libsage.sh
sh_trace sage cache alfa
echo
sh_trace sage cache
echo

sh_trace sage cache ''
echo
sh_trace sage cache
echo

sh_trace sage cache 'C:\ProgramData\Sage'
echo
sh_trace sage cache
