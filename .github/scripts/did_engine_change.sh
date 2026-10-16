#!/usr/bin/env bash
# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# did_engine_change.sh
#
# Reads a list of files from stdin and prints "true" if any file matches
# the engine pattern, or "false" otherwise.
#
# Usage:
#   .github/scripts/git_files_changed.sh <hash|ref> | .github/scripts/did_engine_change.sh
#
# Test:
#
# Pass ("true")
# ```shell
# cat <<EOF | .github/scripts/did_engine_change.sh
# packages/flutter/lib/src/material/button.dart
# engine/src/flutter/shell/common/shell.cc
# dev/bots/test.dart
# EOF
# echo "DEPS" | .github/scripts/did_engine_change.sh
# echo "bin/internal/content_aware_hash.sh" | .github/scripts/did_engine_change.sh
# ```
#
# Fail ("false")
# ```shell
# cat <<EOF | .github/scripts/did_engine_change.sh
# packages/flutter/lib/src/material/button.dart
# dev/bots/test.dart
# EOF
# ```

if grep -qE "^(DEPS|engine/.*|bin/internal/content_aware_hash\.(ps1|sh))$"; then
  echo "true"
else
  echo "false"
fi
