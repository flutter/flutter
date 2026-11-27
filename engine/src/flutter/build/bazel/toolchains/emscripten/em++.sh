#!/bin/bash
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# The compiler of the Emscripten toolchain (emscripten_cc_toolchain_config):
# emcc.py or em++.py from the synced SDK (@emsdk), run under the engine's
# Python with the SDK's paths resolved against the execution root -- an
# action's working directory, so that nothing absolute is written into the
# toolchain. The toolchain configuration sets the paths in the action's
# environment: EM_BIN_PATH (upstream/), EM_CONFIG_PATH (the Python config
# emcc reads through EM_CONFIG, emscripten_config next to this script),
# EM_NODE (the SDK's node) and EM_PYTHON3.
#
# Which of the two drivers runs is the script's own name (emcc.sh, em++.sh;
# emar.sh for the archiver), as with the multicall clang.
#
# EM_FROZEN_CACHE: the SDK's prebuilt system libraries are used as they are
# and never rebuilt into the (read-only, shared) SDK; a variant that is not
# there is an error, not a half-hour build inside a sandbox. The sanity
# check is skipped because its marker file would be written beside the
# cache. Python's bytecode caches would be written into the SDK's tree too.
# emcc expects a PATH to exist (it prepends node's directory to it for the
# closure compiler); an action's environment has none.
set -eu

root="$(pwd -P)"
export EM_ROOT_DIR="$root"
export EM_CONFIG="$root/$EM_CONFIG_PATH"
export EM_FROZEN_CACHE=1
export EMCC_SKIP_SANITY_CHECK=1
export PYTHONDONTWRITEBYTECODE=1
export PATH="${PATH:-/usr/bin:/bin}"

driver="$(basename "$0" .sh)"
exec "$root/$EM_PYTHON3" "$root/$EM_BIN_PATH/emscripten/$driver.py" "$@"
