# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Based on the current repository state, writes on stdout the last commit in the
# git tree that edited either `DEPS` or any file in the `engine/` sub-folder,
# which is used to ensure `bin/internal/engine.version` is set correctly.

# ---------------------------------- NOTE ---------------------------------- #
#
# Please keep the logic in this file consistent with the logic in the
# `last_engine_commit.sh` script in the same directory to ensure that Flutter
# continues to work across all platforms!
#
# https://github.com/flutter/flutter/blob/main/docs/tool/Engine-artifacts.md.
#
# Want to test this script?
# $ cd dev/tools
# $ dart test test/last_engine_commit_test.dart
#
# -------------------------------------------------------------------------- #

$ErrorActionPreference = "Stop"

$progName = Split-Path -parent $MyInvocation.MyCommand.Definition
$flutterRoot = (Get-Item $progName).parent.parent.FullName

cmd /c "git log -1 --pretty=format:%H -- ""$(git rev-parse --show-toplevel)/DEPS"" ""$(git rev-parse --show-toplevel)/engine"""
