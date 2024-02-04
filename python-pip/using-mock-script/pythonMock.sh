ARGUMENT=$1
case $ARGUMENT in
  --version)
    echo "3.x"
    exit 0
    ;;
  show)
    eval "cat $PLACE_HOLDER/pip-show.txt"
    exit 0
    ;;
  freeze)
    eval "cat $PLACE_HOLDER/pip-freeze.txt"
    exit 0
    ;;
esac
exit 23
