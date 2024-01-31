#!/bin/sh
ARGUMENT=$1
case $ARGUMENT in
  --version)
    cat 3.x
    ;;
  show)
    cat pip-show.txt
    ;;
  freeze)
    cat pip-freeze.txt
    ;;
esac
return 0