#!/bin/bash
set -e
echo "Checking formatting..."
cd ..

case "$(uname -s)" in
  Darwin)
    OS="mac-x64"
    ;;
  Linux)
    OS="linux-x64"
    ;;
  *)
    echo "Unknown operating system."
    exit -1
    ;;
esac

CLANG_FORMAT="buildtools/$OS/clang/bin/clang-format"
$CLANG_FORMAT --version

FILES="$(find flutter/ -name '*.cpp' -or -name '*.h' -or -name '*.c' -or -name '*.cc' -or -name '*.m' -or -name '*.mm')"
FAILED_CHECKS=0

for FILE in $FILES; do
  set +e
  RESULT="$(diff -u "$FILE" <($CLANG_FORMAT --style=file "$FILE"))"
  set -e
  if ! [ -z "$RESULT" ]; then
    echo "$RESULT"
    FAILED_CHECKS=$(($counter+1))
  fi
done

if [ $FAILED_CHECKS -ne 0 ]; then
  echo "Some files are formatted incorrectly. To fix, apply diffs from above."
fi

exit $FAILED_CHECKS
