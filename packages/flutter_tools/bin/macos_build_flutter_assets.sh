#!/usr/bin/env bash
# Copyright 2018 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

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
case "$build_mode" in
    debug)
        build_target="debug_macos_application"
        ;;
    profile)
        build_target="profile_macos_application"
        ;;
    release)
        build_target="release_macos_application"
        ;;
    *)
        EchoError "Unknown build mode ${build_mode}"
        exit -1
        ;;
esac

# The path where the input/output xcfilelists are stored. These are used by xcode
# to conditionally skip this script phase if neither have changed.
build_inputs_path="${SOURCE_ROOT}/Flutter/ephemeral/FlutterInputs.xcfilelist"
build_outputs_path="${SOURCE_ROOT}/Flutter/ephemeral/FlutterOutputs.xcfilelist"

# Precache artifacts
RunCommand "${FLUTTER_ROOT}/bin/flutter" --suppress-analytics               \
    ${verbose_flag}                                                         \
    precache                                                                \
    --no-android                                                            \
    --no-ios                                                                \
    --macos

# TODO(jonahwilliams): support flavors https://github.com/flutter/flutter/issues/32923
RunCommand "${FLUTTER_ROOT}/bin/flutter" --suppress-analytics               \
    ${verbose_flag}                                                         \
    ${flutter_engine_flag}                                                  \
    ${local_engine_flag}                                                    \
    assemble                                                                \
    -dTargetFile="${target_path}"                                           \
    -dTargetPlatform=darwin-x64                                             \
    -dBuildMode=debug                                                       \
    --build-inputs="${build_inputs_path}"                                   \
    --build-outputs="${build_outputs_path}"                                 \
    "${build_target}"
