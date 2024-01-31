#!/bin/sh
ARGUMENT=$1
case $ARGUMENT in
  --version)
    cat 3.x
    ;;
  show)
    cat $WORKSPACE/pip-show.txt
    ;;
  freeze)
    cat $WORKSPACE/pip-freeze.txt
    ;;
esac
return 0
