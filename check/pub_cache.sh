#!/bin/dash -e
sh-trace sage cache alfa
echo
sh-trace sage cache
echo

sh-trace sage cache ''
echo
sh-trace sage cache
echo

sh-trace sage cache 'C:\ProgramData\Sage'
echo
sh-trace sage cache
