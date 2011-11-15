#!/usr/bin/env bash

case "$1" in
run)
    # Watch CoffeeScript files in `lib`, compile and output them to `scripts`
    coffee -o scripts/ -cw lib/
;;
esac
