#!/usr/bin/env bash
# Copyright 2019 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -e

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
RunCommand pushd "${PROJECT_DIR}" > /dev/null

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

# Copy the framework and handle local engine builds.
if [[ -n "$FLUTTER_ENGINE" ]]; then
  flutter_engine_flag="--local-engine-src-path=${FLUTTER_ENGINE}"
fi

artifacts_path="${FLUTTER_ROOT}/bin/cache/artifacts/engine/linux-x64"
if [[ -n "$LOCAL_ENGINE" ]]; then
  if [[ $(echo "$LOCAL_ENGINE" | tr "[:upper:]" "[:lower:]") != *"$build_mode"* ]]; then
    EchoError "========================================================================"
    EchoError "ERROR: Requested build with Flutter local engine at '${LOCAL_ENGINE}'"
    EchoError "This engine is not compatible with FLUTTER_BUILD_MODE: '${build_mode}'."
    EchoError "You can fix this by updating the LOCAL_ENGINE environment variable, or"
    EchoError "by running:"
    EchoError "  flutter build linux --local-engine=host_${build_mode}"
    EchoError "or"
    EchoError "  flutter build linux --local-engine=host_${build_mode}_unopt"
    EchoError "========================================================================"
    exit -1
  fi
  local_engine_flag="--local-engine=${LOCAL_ENGINE}"
  artifacts_path="${FLUTTER_ENGINE}/out/${LOCAL_ENGINE}/"
fi

flutter_artifact_copy_dir="linux/flutter/cache"
RunCommand rm -rf "${flutter_artifact_copy_dir}"
RunCommand mkdir -p -- "${flutter_artifact_copy_dir}"
RunCommand cp "${artifacts_path}"/*.h "${flutter_artifact_copy_dir}"/
RunCommand cp "${artifacts_path}"/*.so "${flutter_artifact_copy_dir}"/
RunCommand cp "${artifacts_path}"/icudtl.dat "${flutter_artifact_copy_dir}"/
RunCommand cp -r "${artifacts_path}/cpp_client_wrapper" \
    "${flutter_artifact_copy_dir}/"

RunCommand "${FLUTTER_ROOT}/bin/flutter" --suppress-analytics               \
    ${verbose_flag}                                                         \
    build bundle                                                            \
    --target-platform=linux-x64                                             \
    --target="${target_path}"                                               \
    --${BUILD}                                                              \
    ${track_widget_creation_flag}                                           \
    ${flutter_engine_flag}                                                  \
    ${local_engine_flag}
