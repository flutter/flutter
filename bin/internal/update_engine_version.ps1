# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Based on the current repository state, writes the following two files to disk:
#
# bin/cache/engine.stamp <-- SHA of the commit that engine artifacts were built
# bin/cache/engine.realm <-- optional; ; whether the SHA is from presubmit builds or staging (bringup: true).

# ---------------------------------- NOTE ---------------------------------- #
#
# Please keep the logic in this file consistent with the logic in the
# `update_engine_version.sh` script in the same directory to ensure that Flutter
# continues to work across all platforms!
#
# https://github.com/flutter/flutter/blob/main/docs/tool/Engine-artifacts.md.
#
# Want to test this script?
# $ cd dev/tools
# $ dart test test/update_engine_version_test.dart
#
# -------------------------------------------------------------------------- #

$ErrorActionPreference = "Stop"

$progName = Split-Path -parent $MyInvocation.MyCommand.Definition
$flutterRoot = (Get-Item $progName).parent.parent.FullName

# Generate a bin/cache directory, which won't initially exist for a fresh checkout.
New-Item -Path "$flutterRoot/bin/cache" -ItemType Directory -Force | Out-Null

# Check if FLUTTER_PREBUILT_ENGINE_VERSION is set
#
# This is intended for systems where we intentionally want to (ephemerally) use
# a specific engine artifacts version (which includes the Flutter engine and
# the Dart SDK), such as on CI.
#
# If set, it takes precedence over any other source of engine version.
if (![string]::IsNullOrEmpty($env:FLUTTER_PREBUILT_ENGINE_VERSION)) {
  $engineVersion = $env:FLUTTER_PREBUILT_ENGINE_VERSION

# Check if bin/internal/engine.version exists and is a tracked file in git.
#
# This is intended for a user-shipped stable or beta release, where the release
# has a specific (pinned) engine artifacts version.
#
# If set, it takes precedence over the git hash.
} elseif (git -C "$flutterRoot" ls-files bin/internal/engine.version) {
  $engineVersion = Get-Content -Path "$flutterRoot/bin/internal/engine.version"

# Fallback to using git to triangulate which upstream/master (or origin/master)
# the current branch is forked from, which would be the last version of the
# engine artifacts built from CI.
} else {
  $ErrorActionPreference = "Continue"
  git -C "$flutterRoot" remote get-url upstream *> $null
  $exitCode = $?
  $ErrorActionPreference = "Stop"
  if ($exitCode) {
    $engineVersion = (git -C "$flutterRoot"  merge-base HEAD upstream/master)
  } else {
    $engineVersion = (git -C "$flutterRoot"  merge-base HEAD origin/master)
  }
}

# Write the engine version out so downstream tools know what to look for.
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText("$flutterRoot/bin/cache/engine.stamp", $engineVersion, $utf8NoBom)

# The realm on CI is passed in.
if ($Env:FLUTTER_REALM) {
    [System.IO.File]::WriteAllText("$flutterRoot/bin/cache/engine.realm", $Env:FLUTTER_REALM, $utf8NoBom)
} else {
    [System.IO.File]::WriteAllText("$flutterRoot/bin/cache/engine.realm", "", $utf8NoBom)
}
