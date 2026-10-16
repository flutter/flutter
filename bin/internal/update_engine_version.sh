#!/usr/bin/env bash
# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Based on the current repository state, writes the following two files to disk:
#
# bin/cache/engine.stamp <-- SHA of the commit that engine artifacts were built
# bin/cache/engine.realm <-- optional; whether the SHA is from presubmit builds or staging (bringup: true).
#
# *DOES NOT* update engine.version. To update engine.version run
# `bin/internal/last_engine_commit.sh > bin/internal/engine.version`

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

FLUTTER_ROOT="$(dirname "$(dirname "$(dirname "${BASH_SOURCE[0]}")")")"

# Generate a bin/cache directory, which won't initially exist for a fresh checkout.
mkdir -p "$FLUTTER_ROOT/bin/cache"

FALLBACK_STAMP="$FLUTTER_ROOT/bin/cache/engine_fallback.stamp"

STRICT_ENGINE_VERSION=false
case "${FLUTTER_STRICT_ENGINE_VERSION}" in
  1|[Tt][Rr][Uu][Ee])
    STRICT_ENGINE_VERSION=true
    ;;
  0|[Ff][Aa][Ll][Ss][Ee])
    STRICT_ENGINE_VERSION=false
    ;;
  *)
    if [ -n "${LUCI_CONTEXT}" ]; then
      STRICT_ENGINE_VERSION=true
    fi
    ;;
esac

# Check if FLUTTER_PREBUILT_ENGINE_VERSION is set
#
# This is intended for systems where we intentionally want to (ephemerally) use
# a specific engine artifacts version (which includes the Flutter engine and
# the Dart SDK), such as on CI.
#
# If set, it takes precedence over any other source of engine version.
if [ -n "${FLUTTER_PREBUILT_ENGINE_VERSION}" ]; then
  ENGINE_VERSION="${FLUTTER_PREBUILT_ENGINE_VERSION}"
  if [ -f "$FALLBACK_STAMP" ]; then
    rm -f "$FALLBACK_STAMP"
  fi

# Check if bin/internal/engine.version exists and is a tracked file in git.
#
# This is intended for a user-shipped stable or beta release, where the release
# has a specific (pinned) engine artifacts version.
#
# If set, it takes precedence over the git hash.
elif [ -n "$(git -C "$FLUTTER_ROOT" ls-files bin/internal/engine.version)" ]; then
  ENGINE_VERSION="$(< "$FLUTTER_ROOT/bin/internal/engine.version")"
  ENGINE_VERSION="${ENGINE_VERSION//[[:space:]]/}"
  if [ -f "$FALLBACK_STAMP" ]; then
    rm -f "$FALLBACK_STAMP"
  fi

# Otherwise, compute the content-aware hash of the engine and DEPS at HEAD.
# If a previous run fell back to merge-base artifacts for this exact content
# hash (recorded in engine_fallback.stamp), reuse the fallback hash so we do
# not retry downloading the missing hash on every invocation.
else
  ENGINE_VERSION=$("$FLUTTER_ROOT/bin/internal/content_aware_hash.sh")
  if [ "$STRICT_ENGINE_VERSION" != "true" ] && [ -z "${FLUTTER_REALM}" ] && [ -f "$FALLBACK_STAMP" ]; then
    FALLBACK_CONTENT=$(< "$FALLBACK_STAMP")
    FALLBACK_CONTENT="${FALLBACK_CONTENT//[[:space:]]/}"
    FALLBACK_TARGET="${FALLBACK_CONTENT%%:*}"
    FALLBACK_ACTUAL="${FALLBACK_CONTENT#*:}"
    if [ "$FALLBACK_TARGET" = "$ENGINE_VERSION" ] && [ -n "$FALLBACK_ACTUAL" ] && [ "$FALLBACK_ACTUAL" != "$FALLBACK_CONTENT" ]; then
      ENGINE_VERSION="$FALLBACK_ACTUAL"
    else
      rm -f "$FALLBACK_STAMP"
    fi
  elif [ -f "$FALLBACK_STAMP" ]; then
    rm -f "$FALLBACK_STAMP"
  fi
fi

# Write the engine version out so downstream tools know what to look for.
# Use a temporary file and atomic mv to prevent race conditions during parallel flutter executions.
pid=$$
es_tmp="$FLUTTER_ROOT/bin/cache/engine.stamp.tmp.$pid"
trap 'rm -f "$es_tmp"' EXIT
echo "$ENGINE_VERSION" >"$es_tmp" && mv "$es_tmp" "$FLUTTER_ROOT/bin/cache/engine.stamp"
trap - EXIT

# The realm on CI is passed in.
if [ -n "${FLUTTER_REALM}" ]; then
  echo "$FLUTTER_REALM" >"$FLUTTER_ROOT/bin/cache/engine.realm"
else
  echo "" >"$FLUTTER_ROOT/bin/cache/engine.realm"
fi
