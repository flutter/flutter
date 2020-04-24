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
CLANG_FILETYPES="*.c *.cc *.cpp *.h *.m *.mm"
DIFF_OPTS="-U0 --no-color --name-only"

if git remote get-url upstream >/dev/null 2>&1; then
  UPSTREAM=upstream
else
  UPSTREAM=origin
fi;


BASE_SHA="$(git fetch $UPSTREAM master > /dev/null 2>&1 && \
           (git merge-base --fork-point FETCH_HEAD HEAD || git merge-base FETCH_HEAD HEAD))"
# Disable glob matching otherwise a file in the current directory that matches
# $CLANG_FILETYPES will cause git to query for that exact file instead of doing
# a match.
set -f
CLANG_FILES_TO_CHECK="$(git ls-files $CLANG_FILETYPES)"
set +f
FAILED_CHECKS=0
for f in $CLANG_FILES_TO_CHECK; do
  set +e
  CUR_DIFF="$(diff -u "$f" <("$CLANG_FORMAT" --style=file "$f"))"
  set -e
  if [[ ! -z "$CUR_DIFF" ]]; then
    echo "$CUR_DIFF"
    FAILED_CHECKS=$(($FAILED_CHECKS+1))
  fi
done

GOOGLE_JAVA_FORMAT="../third_party/android_tools/google-java-format/google-java-format-1.7-all-deps.jar"
if [[ -f "$GOOGLE_JAVA_FORMAT" && -f "$(which java)" ]]; then
  java -jar "$GOOGLE_JAVA_FORMAT" --version 2>&1
  JAVA_FILETYPES="*.java"
  JAVA_FILES_TO_CHECK="$(git diff $DIFF_OPTS $BASE_SHA -- $JAVA_FILETYPES)"
  for f in $JAVA_FILES_TO_CHECK; do
    set +e
    CUR_DIFF="$(diff -u "$f" <(java -jar "$GOOGLE_JAVA_FORMAT" "$f"))"
    set -e
    if [[ ! -z "$CUR_DIFF" ]]; then
      echo "$CUR_DIFF"
      FAILED_CHECKS=$(($FAILED_CHECKS+1))
    fi
  done
else
  echo "WARNING: Cannot find google-java-format, skipping Java file formatting!"
fi

if [[ $FAILED_CHECKS -ne 0 ]]; then
  echo ""
  echo "ERROR: Some files are formatted incorrectly. To fix, run \`./ci/format.sh | patch -p0\` from the flutter/engine/src/flutter directory."
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

# Check GN format consistency
./ci/check_gn_format.py --dry-run --root-directory . --gn-binary "third_party/gn/gn"
