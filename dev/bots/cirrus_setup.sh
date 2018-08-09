#!/bin/bash
set -e

# This script is only meant to be run by the Cirrus CI system, not locally.
# It must be run from the root of the Flutter repo.

# Collects log output in a tmpfile, but only prints it if the command fails.
function log_on_fail() {
  local COMMAND="$@"
  local TMPDIR="$(mktemp -d)"
  local TMPFILE="$TMPDIR/command.log"
  local EXIT=0
  if ("$@" > "$TMPFILE" 2>&1); then
    echo "'$COMMAND' succeeded."
  else
    EXIT=$?
    cat "$TMPFILE" 1>&2
    echo "FAIL: '$COMMAND' exited with code $EXIT" 1>&2
  fi
  rm -rf "$TMPDIR"
  return "$EXIT"
}

function accept_android_licenses() {
  yes "y" | flutter doctor --android-licenses
}

echo "Flutter SDK directory is: $PWD"

# Run flutter to download dependencies and precompile things, and to disable
# analytics on the bots.
echo "Downloading build dependencies and pre-compiling Flutter snapshot"
log_on_fail ./bin/flutter config --no-analytics

# Run doctor, to print it to the log for debugging purposes.
./bin/flutter doctor -v

# Accept licenses.
log_on_fail accept_android_licenses && echo "Android licenses accepted."

# Run pub get in all the repo packages.
echo "Updating packages for Flutter."
log_on_fail ./bin/flutter update-packages
