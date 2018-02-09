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
CLANG_FORMAT_DIFF="../buildtools/$OS/clang/share/clang/clang-format-diff.py"
$CLANG_FORMAT --version

# Compute the diffs.
FILETYPES="*.c *.cc *.cpp *.h *.m *.mm"
DIFF_OPTS="-U0 --no-color"
DIFFS="$(git diff $DIFF_OPTS -- master $FILETYPES | "$CLANG_FORMAT_DIFF" -p1 -binary "$CLANG_FORMAT")"

if [[ ! -z "$DIFFS" ]]; then
  echo ""
  echo "ERROR: Some files are formatted incorrectly. To fix, apply diffs below via patch -p0:"
  echo "$DIFFS"
  exit 1
fi
