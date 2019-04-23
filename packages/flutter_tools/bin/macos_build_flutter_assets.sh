#!/usr/bin/env bash
# Copyright 2018 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# TODO(jonahwilliams): refactor this and xcode_backend.sh into one script
# once macOS supports the same configuration as iOS.

RunCommand() {
  if [[ -n "$VERBOSE_SCRIPT_LOGGING" ]]; then
    echo "♦ $*"
  fi
  "$@"
  return $?
}

EchoError() {
  echo "$@" 1>&2
}

# Set the working directory to the project root
project_path="${SOURCE_ROOT}/.."
RunCommand pushd "${project_path}" > /dev/null

# Set the verbose flag.
verbose_flag=""
if [[ -n "$VERBOSE_SCRIPT_LOGGING" ]]; then
    verbose_flag="--verbose"
fi

# Set the target file.
target_path="lib/main.dart"
if [[ -n "$FLUTTER_TARGET" ]]; then
    target_path="${FLUTTER_TARGET}"
fi

# Set the track widget creation flag.
track_widget_creation_flag=""
if [[ -n "$TRACK_WIDGET_CREATION" ]]; then
  track_widget_creation_flag="--track-widget-creation"
fi

# Set the build mode
build_mode="$(echo "${FLUTTER_BUILD_MODE:-${CONFIGURATION}}" | tr "[:upper:]" "[:lower:]")"

RunCommand "${FLUTTER_ROOT}/bin/flutter" --suppress-analytics               \
    ${verbose_flag}                                                         \
    build bundle                                                            \
    --target-platform=darwin-x64                                            \
    --target="${target_path}"                                               \
    --${build_mode}                                                         \
    ${track_widget_creation_flag}
