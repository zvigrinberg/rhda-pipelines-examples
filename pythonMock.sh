#!/bin/sh
ARGUMENT=$1
case $ARGUMENT in
  --version)
    echo "3.x"
    exit 0
    ;;
  show)
    eval "cat ${WORKSPACE_PATH}/pip-show.txt"
    exit 0
    ;;
  freeze)
    eval "cat ${WORKSPACE_PATH}/pip-freeze.txt"
    exit 0
    ;;
esac
exit 23
