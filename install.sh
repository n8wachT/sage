#!/bin/dash
find "$PWD" -executable -type f -name 'sage*' -exec ln -sfvt /usr/local/bin {} +
