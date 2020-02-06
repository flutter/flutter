#!/usr/bin/env bash
# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# TODO(jonahwilliams): refactor this and xcode_backend.sh into one script
# once iOS is using 'assemble'.
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

# Set the build mode
build_mode="$(echo "${FLUTTER_BUILD_MODE:-${CONFIGURATION}}" | tr "[:upper:]" "[:lower:]")"

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

# The path where the input/output xcfilelists are stored. These are used by xcode
# to conditionally skip this script phase if neither have changed.
ephemeral_dir="${SOURCE_ROOT}/Flutter/ephemeral"
build_inputs_path="${ephemeral_dir}/FlutterInputs.xcfilelist"
build_outputs_path="${ephemeral_dir}/FlutterOutputs.xcfilelist"

icon_tree_shaker_flag="false"
if [[ -n "$TREE_SHAKE_ICONS" ]]; then
  icon_tree_shaker_flag="true"
fi

RunCommand "${FLUTTER_ROOT}/bin/flutter" --suppress-analytics               \
    ${verbose_flag}                                                         \
    ${flutter_engine_flag}                                                  \
    ${local_engine_flag}                                                    \
    assemble                                                                \
    -dTargetPlatform=darwin-x64                                             \
    -dTargetFile="${target_path}"                                           \
    -dBuildMode="${build_mode}"                                             \
    -dFontSubset="${icon_tree_shaker_flag}"                                 \
    --build-inputs="${build_inputs_path}"                                   \
    --build-outputs="${build_outputs_path}"                                 \
    --output="${ephemeral_dir}"                                             \
   "${build_mode}_macos_bundle_flutter_assets"
