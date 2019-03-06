#!/bin/bash
set -e

function error() {
  echo "$@" 1>&2
}

# This script is only meant to be run by the Cirrus CI system, not locally.
# It must be run from the root of the Flutter repo.

function accept_android_licenses() {
  yes "y" | flutter doctor --android-licenses > /dev/null 2>&1
}

echo "Flutter SDK directory is: $PWD"

# Run flutter to download dependencies and precompile things, and to disable
# analytics on the bots.
echo "Downloading build dependencies and pre-compiling Flutter snapshot"
./bin/flutter config --no-analytics

# Run doctor, to print it to the log for debugging purposes.
./bin/flutter doctor -v

# Accept licenses.
echo "Accepting Android licenses."
accept_android_licenses || (error "Accepting Android licenses failed." && false)

# Run pub get in all the repo packages.
echo "Updating packages for Flutter."
./bin/flutter update-packages
