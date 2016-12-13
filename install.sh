#!/bin/dash
find "$PWD" -executable -type f -name 'sage*' -exec ln -sft /usr/local/bin {} +
