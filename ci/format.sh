#!/bin/bash
#
# Code formatting presubmit
#
# This presubmit script ensures that code under the src/flutter directory is
# formatted according to the Flutter engine style requirements. On failure, a
# diff is emitted that can be applied from within the src/flutter directory
# via:
#
# patch -p0 < diff.patch

set -e
echo "Checking formatting..."

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

# Tools
CLANG_FORMAT="../buildtools/$OS/clang/bin/clang-format"
$CLANG_FORMAT --version

# Compute the diffs.
FILETYPES="*.c *.cc *.cpp *.h *.m *.mm"
DIFF_OPTS="-U0 --no-color --name-only"

if git remote get-url upstream >/dev/null 2>&1; then
  UPSTREAM=upstream
else
  UPSTREAM=origin
fi;


BASE_SHA="$(git fetch $UPSTREAM master > /dev/null 2>&1 && \
           (git merge-base --fork-point FETCH_HEAD HEAD || git merge-base FETCH_HEAD HEAD))"
FILES_TO_CHECK="$(git diff $DIFF_OPTS $BASE_SHA..HEAD -- $FILETYPES)"

FAILED_CHECKS=0
for f in $FILES_TO_CHECK; do
  set +e
  CUR_DIFF="$(diff -u "$f" <("$CLANG_FORMAT" --style=file "$f"))"
  set -e
  if [[ ! -z "$CUR_DIFF" ]]; then
    echo "$CUR_DIFF"
    FAILED_CHECKS=$(($FAILED_CHECKS+1))
  fi
done

if [[ $FAILED_CHECKS -ne 0 ]]; then
  echo ""
  echo "ERROR: Some files are formatted incorrectly. To fix, apply diffs above via patch -p0."
  exit 1
fi

FILETYPES="*.dart"

set +e
TRAILING_SPACES=$(git diff $DIFF_OPTS $BASE_SHA..HEAD -- $FILETYPES | xargs grep --line-number --with-filename '[[:blank:]]\+$')
set -e

if [[ ! -z "$TRAILING_SPACES" ]]; then
  echo "$TRAILING_SPACES"
  echo ""
  echo "ERROR: Some files have trailing spaces. To fix, try something like \`find . -name "*.dart" -exec sed -i -e 's/\s\+$//' {} \;\`."
  exit 1
fi
