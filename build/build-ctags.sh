#!/bin/bash

# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

if [[ a"`ctags --version | head -1 | grep \"^Exuberant Ctags\"`" == "a" ]]; then
  cat <<EOF
  You must be using Exuberant Ctags, not just standard GNU ctags. If you are on
  Debian or a related flavor of Linux, you may want to try running
  apt-get install exuberant-ctags.
EOF
  exit
fi

CHROME_SRC_DIR="$PWD"

fail() {
  echo "Failed to create ctags for $1"
  exit 1
}

ctags_cmd() {
  echo "ctags --languages=C++ $1 --exclude=.git -R -f .tmp_tags"
}

build_dir() {
  local extraexcludes=""
  if [[ a"$1" == "a--extra-excludes" ]]; then
    extraexcludes="--exclude=third_party --exclude=build --exclude=out"
    shift
  fi

  cd "$CHROME_SRC_DIR/$1" || fail $1
  # Redirect error messages so they aren't seen because they are almost always
  # errors about components that you just happen to have not built (NaCl, for
  # example).
  $(ctags_cmd "$extraexcludes") 2> /dev/null || fail $1
  mv -f .tmp_tags tags
}

# We always build the top level but leave all submodules as optional.
build_dir --extra-excludes "" "top level"

# Build any other directies that are listed on the command line.
for dir in $@; do
  build_dir "$1"
  shift
done
