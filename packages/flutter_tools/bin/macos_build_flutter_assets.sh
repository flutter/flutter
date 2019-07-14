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

if [[ -n "$FLUTTER_ENGINE" ]]; then
  flutter_engine_flag="--local-engine-src-path=${FLUTTER_ENGINE}"
fi

if [[ -n "$LOCAL_ENGINE" ]]; then
  if [[ $(echo "$LOCAL_ENGINE" | tr "[:upper:]" "[:lower:]") != *"$build_mode"* ]]; then
    EchoError "========================================================================"
    EchoError "ERROR: Requested build with Flutter local engine at '${LOCAL_ENGINE}'"
    EchoError "This engine is not compatible with FLUTTER_BUILD_MODE: '${build_mode}'."
    EchoError "You can fix this by updating the LOCAL_ENGINE environment variable, or"
    EchoError "by running:"
    EchoError "  flutter build macos --local-engine=host_${build_mode}"
    EchoError "or"
    EchoError "  flutter build macos --local-engine=host_${build_mode}_unopt"
    EchoError "========================================================================"
    exit -1
  fi
  local_engine_flag="--local-engine=${LOCAL_ENGINE}"
fi

# Set the build mode
build_mode="$(echo "${FLUTTER_BUILD_MODE:-${CONFIGURATION}}" | tr "[:upper:]" "[:lower:]")"

# Select the correc target for the given build mode
target_name="debug_macos_application"

RunCommand "${FLUTTER_ROOT}/bin/flutter"                                    \
    ${verbose_flag}                                                         \
    assemble                                                                \
    -dTargetFile="${target_path}"                                           \
    --xcfilelist-path="${SOURCE_ROOT}"                                      \
    --project-dir="${SOURCE_ROOT}/.."                                       \
    ${flutter_engine_flag}                                                  \
    ${local_engine_flag}                                                    \
    ${target_name}                                                          \

