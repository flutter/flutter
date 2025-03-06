#!/usr/bin/env bash
# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Based on the current repository state, writes the following two files to disk:
#
# bin/cache/engine.stamp <-- SHA of the commit that engine artifacts were built
# bin/cache/engine.realm <-- optional; whether the SHA is from presubmit builds or staging (bringup: true).

# ---------------------------------- NOTE ---------------------------------- #
#
# Please keep the logic in this file consistent with the logic in the
# `update_engine_version.ps1` script in the same directory to ensure that Flutter
# continues to work across all platforms!
#
# https://github.com/flutter/flutter/blob/main/docs/tool/Engine-artifacts.md.
#
# Want to test this script?
# $ cd dev/tools
# $ dart test test/update_engine_version_test.dart
#
# -------------------------------------------------------------------------- #

set -e

FLUTTER_ROOT="$(dirname "$(dirname "$(dirname "${BASH_SOURCE[0]}")")")"

# Generate a bin/cache directory, which won't initially exist for a fresh checkout.
mkdir -p "$FLUTTER_ROOT/bin/cache"

# Check if FLUTTER_PREBUILT_ENGINE_VERSION is set
#
# This is intended for systems where we intentionally want to (ephemerally) use
# a specific engine artifacts version (which includes the Flutter engine and
# the Dart SDK), such as on CI.
#
# If set, it takes precedence over any other source of engine version.
if [ -n "${FLUTTER_PREBUILT_ENGINE_VERSION}" ]; then
  ENGINE_VERSION="${FLUTTER_PREBUILT_ENGINE_VERSION}"

# Check if bin/internal/engine.version exists and is a tracked file in git.
#
# This is intended for a user-shipped stable or beta release, where the release
# has a specific (pinned) engine artifacts version.
#
# If set, it takes precedence over the git hash.
elif [ -n "$(git -C "$FLUTTER_ROOT" ls-files bin/internal/engine.version)" ]; then
  ENGINE_VERSION="$(cat "$FLUTTER_ROOT/bin/internal/engine.version")"

# Fallback to using git to triangulate which upstream/master (or origin/master)
# the current branch is forked from, which would be the last version of the
# engine artifacts built from CI.
else
  set +e
  # We fallback to origin/master if upstream is not detected.
  git -C "$FLUTTER_ROOT" remote get-url upstream >/dev/null 2>&1
  exit_code=$?
  set -e

  if [[ $exit_code -eq 0 ]]; then
    ENGINE_VERSION=$(git -C "$FLUTTER_ROOT" merge-base HEAD upstream/master)
  else
    ENGINE_VERSION=$(git -C "$FLUTTER_ROOT" merge-base HEAD origin/master)
  fi
fi

# Write the engine version out so downstream tools know what to look for.
echo $ENGINE_VERSION >"$FLUTTER_ROOT/bin/cache/engine.stamp"

# The realm on CI is passed in.
if [ -n "${FLUTTER_REALM}" ]; then
  echo $FLUTTER_REALM >"$FLUTTER_ROOT/bin/cache/engine.realm"
else
  echo "" >"$FLUTTER_ROOT/bin/cache/engine.realm"
fi
