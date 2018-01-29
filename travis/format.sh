#!/bin/bash
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

CLANG_FORMAT="../buildtools/$OS/clang/bin/clang-format"
$CLANG_FORMAT --version
CLANG_FORMAT_DIFF="../buildtools/$OS/clang/share/clang/clang-format-diff.py"

DIFFS="$(git diff -U0 --no-color master | "$CLANG_FORMAT_DIFF" -p1 -binary "$CLANG_FORMAT")"
if [[ ! -z "$DIFFS" ]]; then
  echo ""
  echo "ERROR: Some files are formatted incorrectly. To fix, apply diffs below:"
  echo "$DIFFS"
fi
