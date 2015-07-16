#!/bin/sh
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Upload the generated output to Google storage.

set -e

if [ ! -d "$1" ]; then
  echo "update.sh <output directory from build-all.sh>"
  exit 1
fi

if echo "$PWD" | grep -qE "/src/third_party/binutils$"; then
  echo -n
else
  echo "update.sh should be run in src/third_party/binutils"
  exit 1
fi

if [ ! -f ~/.boto ]; then
  echo "You need to run 'gsutil config' to set up authentication before running this script."
  exit 1
fi

for DIR in $1/*; do
  # Skip if not directory
  if [ ! -d "$DIR" ]; then
    continue
  fi

  case "$DIR" in
    */i686-pc-linux-gnu)
      export ARCH="Linux_ia32"
      ;;

    */x86_64-unknown-linux-gnu)
      export ARCH="Linux_x64"
      ;;

    *)
      echo "Unknown architecture directory $DIR"
      exit 1
      ;;
  esac

  if [ ! -d "$ARCH" ]; then
    mkdir -p "$ARCH"
  fi

  BINUTILS_TAR_BZ2="$ARCH/binutils.tar.bz2"
  FULL_BINUTILS_TAR_BZ2="$PWD/$BINUTILS_TAR_BZ2"
  if [ -f "${BINUTILS_TAR_BZ2}.sha1" ]; then
    rm "${BINUTILS_TAR_BZ2}.sha1"
  fi
  (cd "$DIR"; tar jcf "$FULL_BINUTILS_TAR_BZ2" .)

  upload_to_google_storage.py --bucket chromium-binutils "$BINUTILS_TAR_BZ2"
  git add -f "${BINUTILS_TAR_BZ2}.sha1"
done

echo "Please commit the new .sha1 to the Chromium repository"
echo ""
echo "# git commit"
