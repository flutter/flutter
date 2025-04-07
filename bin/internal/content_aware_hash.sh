
#!/usr/bin/env bash
# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# ---------------------------------- NOTE ---------------------------------- #
#
# Please keep the logic in this file consistent with the logic in the
# `content_aware_hash.ps1` script in the same directory to ensure that Flutter
# continues to work across all platforms!
#
# -------------------------------------------------------------------------- #

set -e

FLUTTER_ROOT="$(dirname "$(dirname "$(dirname "${BASH_SOURCE[0]}")")")"

unset GIT_DIR
unset GIT_INDEX_FILE
unset GIT_WORK_TREE

git -C "$FLUTTER_ROOT" ls-tree HEAD DEPS engine bin/internal/release-candidate-branch.version bin/internal/content_aware_hash.* | git hash-object --stdin
