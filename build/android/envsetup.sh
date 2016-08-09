#!/bin/bash
# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Sets up environment for building Chromium on Android.

# Make sure we're being sourced (possibly by another script). Check for bash
# since zsh sets $0 when sourcing.
if [[ -n "$BASH_VERSION" && "${BASH_SOURCE:-$0}" == "$0" ]]; then
  echo "ERROR: envsetup must be sourced."
  exit 1
fi

# This only exists to set local variables. Don't call this manually.
android_envsetup_main() {
  local SCRIPT_PATH="$1"
  local SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

  local CURRENT_DIR="$(readlink -f "${SCRIPT_DIR}/../../")"
  if [[ -z "${CHROME_SRC}" ]]; then
    # If $CHROME_SRC was not set, assume current directory is CHROME_SRC.
    local CHROME_SRC="${CURRENT_DIR}"
  fi

  if [[ "${CURRENT_DIR/"${CHROME_SRC}"/}" == "${CURRENT_DIR}" ]]; then
    # If current directory is not in $CHROME_SRC, it might be set for other
    # source tree. If $CHROME_SRC was set correctly and we are in the correct
    # directory, "${CURRENT_DIR/"${CHROME_SRC}"/}" will be "".
    # Otherwise, it will equal to "${CURRENT_DIR}"
    echo "Warning: Current directory is out of CHROME_SRC, it may not be \
  the one you want."
    echo "${CHROME_SRC}"
  fi

  # Allow the caller to override a few environment variables. If any of them is
  # unset, we default to a sane value that's known to work. This allows for
  # experimentation with a custom SDK.
  if [[ -z "${ANDROID_SDK_ROOT}" || ! -d "${ANDROID_SDK_ROOT}" ]]; then
    local ANDROID_SDK_ROOT="${CHROME_SRC}/third_party/android_tools/sdk/"
  fi

  # Add Android SDK tools to system path.
  export PATH=$PATH:${ANDROID_SDK_ROOT}/platform-tools

  # Add Android utility tools to the system path.
  export PATH=$PATH:${ANDROID_SDK_ROOT}/tools/

  # Add Chromium Android development scripts to system path.
  # Must be after CHROME_SRC is set.
  export PATH=$PATH:${CHROME_SRC}/build/android

  export ENVSETUP_GYP_CHROME_SRC=${CHROME_SRC}  # TODO(thakis): Remove.
}
# In zsh, $0 is the name of the file being sourced.
android_envsetup_main "${BASH_SOURCE:-$0}"
unset -f android_envsetup_main

android_gyp() {
  echo "Please call build/gyp_chromium instead. android_gyp is going away."
  "${ENVSETUP_GYP_CHROME_SRC}/build/gyp_chromium" --depth="${ENVSETUP_GYP_CHROME_SRC}" --check "$@"
}
