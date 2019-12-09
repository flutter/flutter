#!/usr/bin/env bash
# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -e

# Update this URL to get another version of the Gradle wrapper.
# If the AOSP folks have changed the layout of their templates, you may also need to update the
# script below to grab the right files...
WRAPPER_SRC_URL="https://android.googlesource.com/platform/tools/base/+archive/0b5c1398d1d04ac245a310de98825cb7b3278e2a/templates.tgz"

case "$(uname -s)" in
  Darwin)
    SHASUM="shasum"
    ;;
  *)
    SHASUM="sha1sum"
    ;;
esac

function follow_links() {
  cd -P "${1%/*}"
  file="$PWD/${1##*/}"
  while [ -h "$file" ]; do
    # On Mac OS, readlink -f doesn't work.
    cd -P "${file%/*}"
    file="$(readlink "$file")"
    cd -P "${file%/*}"
    file="$PWD/${file##*/}"
  done
  echo "$PWD/${file##*/}"
}

# Convert a filesystem path to a format usable by Dart's URI parser.
function path_uri() {
  # Reduce multiple leading slashes to a single slash.
  echo "$1" | sed -E -e "s,^/+,/,"
}

PROG_NAME="$(path_uri "$(follow_links "$BASH_SOURCE")")"
BIN_DIR="$(cd "${PROG_NAME%/*}" ; pwd -P)"
FLUTTER_ROOT="$(cd "${BIN_DIR}/../.." ; pwd -P)"

WRAPPER_VERSION_PATH="$FLUTTER_ROOT/bin/internal/gradle_wrapper.version"
WRAPPER_TEMP_DIR="$FLUTTER_ROOT/bin/cache/gradle-wrapper-temp"

echo "Downloading gradle wrapper..."
rm -rf "$WRAPPER_TEMP_DIR"
mkdir "$WRAPPER_TEMP_DIR"
curl --continue-at - --location --output "$WRAPPER_TEMP_DIR/templates.tgz" "$WRAPPER_SRC_URL" 2>&1

echo
echo "Repackaging files..."
mkdir "$WRAPPER_TEMP_DIR/unpack"
tar xzf "$WRAPPER_TEMP_DIR/templates.tgz" -C "$WRAPPER_TEMP_DIR/unpack" gradle NOTICE

mkdir "$WRAPPER_TEMP_DIR/repack"
mv "$WRAPPER_TEMP_DIR/unpack/gradle/wrapper"/* "$WRAPPER_TEMP_DIR/repack/"
mv "$WRAPPER_TEMP_DIR/unpack/NOTICE" "$WRAPPER_TEMP_DIR/repack/"

pushd "$WRAPPER_TEMP_DIR/repack" > /dev/null
STAMP=`for h in $(find . -type f); do $SHASUM $h; done | $SHASUM | cut -d' ' -f1`
echo "Packaged files:"
tar cvzf ../gradle-wrapper.tgz *
popd > /dev/null

echo
echo "Uploading repackaged gradle wrapper..."
echo "Content hash: $STAMP"
gsutil.py cp -n "$WRAPPER_TEMP_DIR/gradle-wrapper.tgz" "gs://flutter_infra/gradle-wrapper/$STAMP/gradle-wrapper.tgz"

echo "flutter_infra/gradle-wrapper/$STAMP/gradle-wrapper.tgz" > "$WRAPPER_VERSION_PATH"

rm -rf "$WRAPPER_TEMP_DIR"
echo
echo "All done. Updated bin/internal/gradle_wrapper.version, don't forget to commit!"
