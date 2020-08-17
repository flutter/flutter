#!/bin/bash
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Code formatting presubmit script.
#
# This presubmit script ensures that code under the src/flutter directory is
# formatted according to the Flutter engine style requirements.
#
# If failures are found, they can be fixed by re-running the script with the
# --fix option.

set -e

# Needed because if it is set, cd may print the path it changed to.
unset CDPATH

# On Mac OS, readlink -f doesn't work, so follow_links traverses the path one
# link at a time, and then cds into the link destination and find out where it
# ends up.
#
# The function is enclosed in a subshell to avoid changing the working directory
# of the caller.
function follow_links() (
  cd -P "$(dirname -- "$1")"
  file="$PWD/$(basename -- "$1")"
  while [[ -h "$file" ]]; do
    cd -P "$(dirname -- "$file")"
    file="$(readlink -- "$file")"
    cd -P "$(dirname -- "$file")"
    file="$PWD/$(basename -- "$file")"
  done
  echo "$file"
)

SCRIPT_DIR=$(follow_links "$(dirname -- "${BASH_SOURCE[0]}")")
SRC_DIR="$(
  cd "$SCRIPT_DIR/../.."
  pwd -P
)"
FLUTTER_DIR="$SRC_DIR/flutter"

function message() {
  echo "$*" 1>&2
}

function error() {
  echo "ERROR: $*" 1>&2
}

function warning() {
  echo "WARNING: $*" 1>&2
}

function get_base_sha() (
  local upstream
  if git remote get-url upstream >/dev/null 2>&1; then
    upstream=upstream
  else
    upstream=origin
  fi

  cd "$FLUTTER_DIR"
  git fetch "$upstream" master >/dev/null 2>&1
  git merge-base --fork-point FETCH_HEAD HEAD || git merge-base FETCH_HEAD HEAD
)

function check_clang_format() (
  cd "$FLUTTER_DIR"
  message "Checking C++/ObjC formatting..."

  case "$(uname -s)" in
  Darwin)
    OS="mac-x64"
    ;;
  Linux)
    OS="linux-x64"
    ;;
  *)
    error "Unknown operating system."
    return 255
    ;;
  esac

  # Tools
  local clang_format="$SRC_DIR/buildtools/$OS/clang/bin/clang-format"
  "$clang_format" --version 1>&2

  local current_diff
  local clang_files_to_check

  # Compute the diffs.
  local clang_filetypes=("*.c" "*.cc" "*.cpp" "*.h" "*.m" "*.mm")
  clang_files_to_check="$(git ls-files "${clang_filetypes[@]}")"
  local failed_clang_checks=0
  for file in $clang_files_to_check; do
    set +e
    current_diff="$(diff -u "$file" <("$clang_format" --style=file "$file"))"
    set -e
    if [[ -n "$current_diff" ]]; then
      echo "$current_diff"
      failed_clang_checks=$((failed_clang_checks + 1))
    fi
  done

  if [[ $failed_clang_checks -ne 0 ]]; then
    error "$failed_clang_checks C++/ObjC files are formatted incorrectly."
  fi
  return $failed_clang_checks
)

function check_java_format() (
  cd "$FLUTTER_DIR"
  local diff_opts=("-U0" "--no-color" "--name-only")
  message "Checking Java formatting..."
  local google_java_format="$SRC_DIR/third_party/android_tools/google-java-format/google-java-format-1.7-all-deps.jar"
  local failed_java_checks=0
  if [[ -f "$google_java_format" && -n "$(command -v java)" ]]; then
    java -jar "$google_java_format" --version 1>&2
    local java_filetypes=("*.java")
    local java_files_to_check
    java_files_to_check="$(git diff "${diff_opts[@]}" "$BASE_SHA" -- "${java_filetypes[@]}")"
    for file in $java_files_to_check; do
      set +e
      current_diff="$(diff -u "$file" <(java -jar "$google_java_format" "$file"))"
      set -e
      if [[ -n "$current_diff" ]]; then
        echo "$current_diff"
        failed_java_checks=$((failed_java_checks + 1))
      fi
    done
    if [[ $failed_java_checks -ne 0 ]]; then
      error "$failed_java_checks Java files are formatted incorrectly."
    fi
  else
    warning "Cannot find google-java-format, skipping Java file formatting!"
  fi
  return $failed_java_checks
)

# Strips off the "advice" at the end, since this script has different advice.
function do_gn_check() {
  local output
  output="$("$SCRIPT_DIR/check_gn_format.py" --dry-run --root-directory . --gn-binary "third_party/gn/gn")"
  local result=$?
  echo "$output" | grep "ERROR"
  return $result
}

function check_gn_format() (
  cd "$FLUTTER_DIR"
  message "Checking GN formatting..."
  if ! do_gn_check 1>&2; then
    error "The gn file format check failed."
    return 1
  fi
)

function check_whitespace() (
  local diff_opts=("-U0" "--no-color" "--name-only")
  local filetypes="*.dart"
  local trailing_spaces

  message "Checking for trailing whitespace in $filetypes files..." 1>&2
  set +e
  trailing_spaces=$(git diff "${diff_opts[@]}" "$BASE_SHA" -- "$filetypes" | xargs grep --line-number --with-filename '[[:blank:]]\+$')
  set -e

  if [[ -n "$trailing_spaces" ]]; then
    message "$trailing_spaces"
    error "Whitespace check failed. The above files have trailing spaces."
    return 1
  fi
)

function fix_clang_format() {
  local tmpfile
  tmpfile=$(mktemp "fix_clang_format.XXXXXX")
  if check_clang_format >"$tmpfile"; then
    message "No C++/ObjC formatting issues found."
  else
    message "Fixing C++/ObjC formatting issues."
    (
      cd "$SRC_DIR/flutter"
      patch -p0 <"$tmpfile"
    )
  fi
  command rm -f "$tmpfile"
}

function fix_java_format() {
  local tmpfile
  tmpfile=$(mktemp "fix_java_format.XXXXXX")
  if check_java_format >"$tmpfile"; then
    message "No Java formatting issues found."
  else
    message "Fixing Java formatting issues."
    (
      cd "$SRC_DIR/flutter"
      patch -p0 <"$tmpfile"
    )
  fi
  command rm -f "$tmpfile"
}

function fix_gn_format() (
  cd "$FLUTTER_DIR"
  message "Fixing GN formatting..."
  # Check GN format consistency and fix it.
  if ! "$SCRIPT_DIR/check_gn_format.py" --root-directory . --gn-binary "third_party/gn/gn"; then
    error "The GN file format fix failed."
    return 1
  fi
)

function fix_whitespace() {
  if ! check_whitespace; then
    message "Fixing trailing whitespace problems."
    find "$FLUTTER_DIR" -type f -name "*.dart" -print0 | xargs -0 sed -i -e 's/\s\+$//'
  fi
}

BASE_SHA=$(get_base_sha)
message "Checking formatting for files with differences from $BASE_SHA in $FLUTTER_DIR"

if [[ $1 == "--fix" ]]; then
  fix_clang_format
  fix_java_format
  fix_gn_format
  fix_whitespace
  message "Formatting fixed."
else
  failures=0
  if ! check_clang_format; then
    failures=$((failures + 1))
  fi
  if ! check_java_format; then
    failures=$((failures + 1))
  fi
  if ! check_gn_format; then
    failures=$((failures + 1))
  fi
  if ! check_whitespace; then
    failures=$((failures + 1))
  fi
  if [[ $failures -eq 0 ]]; then
    message "No formatting issues found."
  else
    error "Formatting check failed."
    error "To fix, run \"$SCRIPT_DIR/format.sh --fix\""
  fi
  exit $failures
fi
