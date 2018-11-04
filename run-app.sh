#!/bin/sh
prog=$(basename $0)
bindir=$(dirname $(readlink -f $0))

morbo -l http://0.0.0.0:3000 $bindir/app/api.pl
