#!/bin/bash
# Download and extract Jinja2
# Homepage:
# http://jinja.pocoo.org/
# Installation instructions:
# http://jinja.pocoo.org/docs/intro/#from-the-tarball-release
# Download page:
# https://pypi.python.org/pypi/Jinja2
PACKAGE='Jinja2'
VERSION='2.7.1'
PACKAGE_DIR='jinja2'

CHROMIUM_FILES="README.chromium OWNERS get_jinja2.sh"
EXTRA_FILES='LICENSE AUTHORS'
REMOVE_FILES='testsuite'

SRC_URL='https://pypi.python.org/packages/source/'
SRC_URL+="${PACKAGE:0:1}/$PACKAGE/$PACKAGE-$VERSION.tar.gz"
FILENAME="$(basename $SRC_URL)"
MD5_FILENAME="$FILENAME.md5"
SHA512_FILENAME="$FILENAME.sha512"
CHROMIUM_FILES+=" $MD5_FILENAME $SHA512_FILENAME"

BUILD_DIR="$PACKAGE-$VERSION"
THIRD_PARTY="$(dirname $(realpath $(dirname "${BASH_SOURCE[0]}")))"
INSTALL_DIR="$THIRD_PARTY/$PACKAGE_DIR"
OUT_DIR="$INSTALL_DIR/$BUILD_DIR/$PACKAGE_DIR"
OLD_DIR="$THIRD_PARTY/$PACKAGE_DIR.old"

function check_hashes {
  # Hashes generated via:
  # FILENAME=Jinja2-2.7.1.tar.gz
  # md5sum "$FILENAME" > "$FILENAME.md5"
  # sha512sum "$FILENAME" > "$FILENAME.sha512"
  # unset FILENAME

  # MD5
  if ! [ -f "$MD5_FILENAME" ]
  then
    echo "MD5 hash file $MD5_FILENAME not found, could not verify archive"
    exit 1
  fi

  # 32-digit hash, followed by filename
  MD5_HASHFILE_REGEX="^[0-9a-f]{32}  $FILENAME"
  if ! grep --extended-regex --line-regex --silent \
    "$MD5_HASHFILE_REGEX" "$MD5_FILENAME"
  then
    echo "MD5 hash file $MD5_FILENAME does not contain hash for $FILENAME," \
         'could not verify archive'
    echo 'Hash file contents are:'
    cat "$MD5_FILENAME"
    exit 1
  fi

  if ! md5sum --check "$MD5_FILENAME"
  then
    echo 'MD5 hash does not match,' \
         "archive file $FILENAME corrupt or compromised!"
    exit 1
  fi

  # SHA-512
  if ! [ -f "$SHA512_FILENAME" ]
  then
    echo "SHA-512 hash file $SHA512_FILENAME not found," \
         'could not verify archive'
    exit 1
  fi

  # 128-digit hash, followed by filename
  SHA512_HASHFILE_REGEX="^[0-9a-f]{128}  $FILENAME"
  if ! grep --extended-regex --line-regex --silent \
    "$SHA512_HASHFILE_REGEX" "$SHA512_FILENAME"
  then
    echo "SHA-512 hash file $SHA512_FILENAME does not contain hash for" \
         "$FILENAME, could not verify archive"
    echo 'Hash file contents are:'
    cat "$SHA512_FILENAME"
    exit 1
  fi

  if ! sha512sum --check "$SHA512_FILENAME"
  then
    echo 'SHA-512 hash does not match,' \
         "archive file $FILENAME corrupt or compromised!"
    exit 1
  fi
}


################################################################################
# Body

cd "$INSTALL_DIR"
echo "Downloading $SRC_URL"
curl --remote-name "$SRC_URL"
check_hashes
tar xvzf "$FILENAME"
# Copy extra files over
for FILE in $CHROMIUM_FILES
do
  cp "$FILE" "$OUT_DIR"
done

cd "$BUILD_DIR"
for FILE in $EXTRA_FILES
do
  cp "$FILE" "$OUT_DIR"
done

cd "$OUT_DIR"
for FILE in $REMOVE_FILES
do
  rm -fr "$FILE"
done

# Replace with new directory
cd ..
mv "$INSTALL_DIR" "$OLD_DIR"
mv "$PACKAGE_DIR" "$INSTALL_DIR"
cd "$INSTALL_DIR"
rm -fr "$OLD_DIR"
