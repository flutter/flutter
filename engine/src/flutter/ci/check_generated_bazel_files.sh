#!/bin/bash
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# Checks that the files tools/gn_to_bazel generates are current: every
# generated BUILD.bazel (from its BUILD.gn), the hand-written lists that
# repeat a GN file's, ci/builders/BUILD.bazel, ci/builders/configs.bazelrc
# and build/bazel/builds.json (from the builder files), and
# lib/web_ui/felt_config.bzl (from lib/web_ui/test/felt_config.yaml). A
# change to a BUILD.gn or a builder file is complete when
# `dart bin/gn_to_bazel.dart` has been rerun in flutter/tools/gn_to_bazel
# (tools/gn_to_bazel/README.md); this step fails until it has. It runs on
# the checkout's prebuilt Dart SDK and without buildifier -- the emitter
# writes buildifier's format -- so it needs nothing a bot does not have.

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

function dart_bin() {
  dart_path="$1/flutter/third_party/dart/tools/sdks/dart-sdk/bin"
  if [[ ! -e "$dart_path" ]]; then
    dart_path="$1/third_party/dart/tools/sdks/dart-sdk/bin"
  fi
  echo "$dart_path"
}

SCRIPT_DIR=$(follow_links "$(dirname -- "${BASH_SOURCE[0]}")")
SRC_DIR="$(cd "$SCRIPT_DIR/../.."; pwd -P)"
DART_BIN=$(dart_bin "$SRC_DIR")
DART="${DART_BIN}/dart"

cd "$SRC_DIR/flutter/tools/gn_to_bazel"
"$DART" bin/gn_to_bazel.dart --check --buildifier=none --root="$SRC_DIR"
