#!/usr/bin/env bash
# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

<<<<<<< HEAD
# Want to test this script?
# $ cd dev/tools
# $ dart test test/update_engine_version_test.dart
=======
# Based on the current repository state, writes the following two files to disk:
#
# bin/cache/engine.stamp <-- SHA of the commit that engine artifacts were built
# bin/cache/engine.realm <-- optional; whether the SHA is from presubmit builds or staging (bringup: true).
>>>>>>> b25305a8832cfc6ba632a7f87ad455e319dccce8

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

# When called from a submodule hook; these will override `git -C dir`
unset GIT_DIR
unset GIT_INDEX_FILE
unset GIT_WORK_TREE

<<<<<<< HEAD
# Allow overriding the intended engine version via FLUTTER_PREBUILT_ENGINE_VERSION.
#
# This is for systems, such as Github Actions, where we know ahead of time the
# base-ref we want to use (to download the engine binaries and avoid trying
# to compute one below), or for the Dart HH bot, which wants to try the current
# Flutter framework/engine with a different Dart SDK.
#
# This environment variable is EXPERIMENTAL. If you are not on the Flutter infra
# or Dart infra teams, this code path might be removed at anytime and cease
# functioning. Please file an issue if you have workflow needs.
if [ -n "${FLUTTER_PREBUILT_ENGINE_VERSION}" ]; then
  ENGINE_VERSION="${FLUTTER_PREBUILT_ENGINE_VERSION}"
fi

FLUTTER_ROOT="$(dirname "$(dirname "$(dirname "${BASH_SOURCE[0]}")")")"

# On stable, beta, and release tags, the engine.version is tracked by git - do not override it.
TRACKED_ENGINE="$(git -C "$FLUTTER_ROOT" ls-files bin/internal/engine.version)"
if [[ -n "$TRACKED_ENGINE" ]]; then
  exit
fi

# Test for fusion repository and no environment variable override.
if [ -z "$ENGINE_VERSION" ] && [ -f "$FLUTTER_ROOT/DEPS" ] && [ -f "$FLUTTER_ROOT/engine/src/.gn" ]; then
  # In a fusion repository; the engine.version comes from the git hashes.
  if [ -z "${LUCI_CONTEXT}" ]; then
    set +e
    # Run the git command and capture the exit code
    git -C "$FLUTTER_ROOT" remote get-url upstream > /dev/null 2>&1
    exit_code=$?
    set -e
=======
FLUTTER_ROOT="$(dirname "$(dirname "$(dirname "${BASH_SOURCE[0]}")")")"

# Generate a bin/cache directory, which won't initially exist for a fresh checkout.
mkdir -p "$FLUTTER_ROOT/bin/cache"
>>>>>>> b25305a8832cfc6ba632a7f87ad455e319dccce8

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
<<<<<<< HEAD
    ENGINE_VERSION=$(git -C "$FLUTTER_ROOT" rev-parse HEAD)
  fi
fi

# Write the engine version out so downstream tools know what to look for.
echo $ENGINE_VERSION > "$FLUTTER_ROOT/bin/internal/engine.version"

# The realm on CI is passed in.
if [ -n "${FLUTTER_REALM}" ]; then
  echo $FLUTTER_REALM > "$FLUTTER_ROOT/bin/internal/engine.realm"
=======
    ENGINE_VERSION=$(git -C "$FLUTTER_ROOT" merge-base HEAD origin/master)
  fi
>>>>>>> b25305a8832cfc6ba632a7f87ad455e319dccce8
fi

# Write the engine version out so downstream tools know what to look for.
echo $ENGINE_VERSION >"$FLUTTER_ROOT/bin/cache/engine.stamp"

# The realm on CI is passed in.
if [ -n "${FLUTTER_REALM}" ]; then
  echo $FLUTTER_REALM >"$FLUTTER_ROOT/bin/cache/engine.realm"
else
  echo "" >"$FLUTTER_ROOT/bin/cache/engine.realm"
fi
