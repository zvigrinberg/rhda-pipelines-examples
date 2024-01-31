#!/bin/sh
ARGUMENT=$1
case $ARGUMENT in
  --version)
    cat 3.x
    ;;
  show)
    cat $WORKSPACE_PATH/pip-show.txt
    ;;
  freeze)
    cat $WORKSPACE_PATH/pip-freeze.txt
    ;;
esac
exit 0
