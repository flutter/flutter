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

# Copy the framework and handle local engine builds.
framework_name="FlutterMacOS.framework"
ephemeral_dir="${SOURCE_ROOT}/Flutter/ephemeral"
framework_path="${FLUTTER_ROOT}/bin/cache/artifacts/engine/darwin-x64"
flutter_framework="${framework_path}/${framework_name}"

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
  flutter_framework="${FLUTTER_ENGINE}/out/${LOCAL_ENGINE}/${framework_name}"
fi

RunCommand mkdir -p -- "$ephemeral_dir"
RunCommand rm -rf -- "${ephemeral_dir}/${framework_name}"
RunCommand cp -Rp -- "${flutter_framework}" "${ephemeral_dir}"

# Set the build mode
build_mode="$(echo "${FLUTTER_BUILD_MODE:-${CONFIGURATION}}" | tr "[:upper:]" "[:lower:]")"

RunCommand "${FLUTTER_ROOT}/bin/flutter" --suppress-analytics               \
    ${verbose_flag}                                                         \
    build bundle                                                            \
    --target-platform=darwin-x64                                            \
    --target="${target_path}"                                               \
    --${build_mode}                                                         \
    ${track_widget_creation_flag}                                           \
    ${flutter_engine_flag}                                                  \
    ${local_engine_flag}
