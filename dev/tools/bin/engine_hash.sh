#!/usr/bin/env bash
# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# ---------------------------------- NOTE ---------------------------------- #
#
# This file will appear unused within the monorepo. It is used internally
# (in google3) as part of the roll process, and care should be put before 
# making changes.
#
# See cl/688973229.
#
# -------------------------------------------------------------------------- #

# Test for fusion repository
if [ -f "$FLUTTER_ROOT/DEPS" ] && [ -f "$FLUTTER_ROOT/engine/src/.gn" ]; then
    BRANCH=$(git -C "$FLUTTER_ROOT" rev-parse --abbrev-ref HEAD)

    # In a fusion repository; the engine.version comes from the git hashes.
    if [ -z "${LUCI_CONTEXT}" ]; then
      ENGINE_VERSION=$(git -C "$FLUTTER_ROOT" merge-base HEAD upstream/master)
    else
      ENGINE_VERSION=$(git -C "$FLUTTER_ROOT" rev-parse HEAD)
    fi
else
    # Non-fusion repository - these files will exist
    ENGINE_VERSION=$(cat "$FLUTTER_ROOT/bin/internal/engine.version")
fi

echo $ENGINE_VERSION
