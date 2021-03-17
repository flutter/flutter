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

BuildApp() {
  # Set the working directory to the project root
  local project_path="${SOURCE_ROOT}/.."
  RunCommand pushd "${project_path}" > /dev/null

  # Set the verbose flag.
  local verbose_flag=""
  if [[ -n "$VERBOSE_SCRIPT_LOGGING" ]]; then
      verbose_flag="--verbose"
  fi

  # Set the target file.
  local target_path="lib/main.dart"
  if [[ -n "$FLUTTER_TARGET" ]]; then
      target_path="${FLUTTER_TARGET}"
  fi

  if [[ -n "$FLUTTER_ENGINE" ]]; then
    flutter_engine_flag="--local-engine-src-path=${FLUTTER_ENGINE}"
  fi

  # Set the build mode
  local build_mode="$(echo "${FLUTTER_BUILD_MODE:-${CONFIGURATION}}" | tr "[:upper:]" "[:lower:]")"

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
  local ephemeral_dir="${SOURCE_ROOT}/Flutter/ephemeral"
  local build_inputs_path="${ephemeral_dir}/FlutterInputs.xcfilelist"
  local build_outputs_path="${ephemeral_dir}/FlutterOutputs.xcfilelist"

  local performance_measurement_option=""
  if [[ -n "$PERFORMANCE_MEASUREMENT_FILE" ]]; then
    performance_measurement_option="--performance-measurement-file=${PERFORMANCE_MEASUREMENT_FILE}"
  fi

  local bundle_sksl_path=""
  if [[ -n "$BUNDLE_SKSL_PATH" ]]; then
    bundle_sksl_path="-iBundleSkSLPath=${BUNDLE_SKSL_PATH}"
  fi

  local code_size_directory=""
  if [[ -n "$CODE_SIZE_DIRECTORY" ]]; then
    code_size_directory="-dCodeSizeDirectory=${CODE_SIZE_DIRECTORY}"
  fi

  RunCommand "${FLUTTER_ROOT}/bin/flutter"                                    \
      ${verbose_flag}                                                         \
      ${flutter_engine_flag}                                                  \
      ${local_engine_flag}                                                    \
      assemble                                                                \
      --no-version-check                                                      \
      ${performance_measurement_option}                                       \
      -dTargetPlatform=darwin-x64                                             \
      -dTargetFile="${target_path}"                                           \
      -dBuildMode="${build_mode}"                                             \
      -dTreeShakeIcons="${TREE_SHAKE_ICONS}"                                  \
      -dDartObfuscation="${DART_OBFUSCATION}"                                 \
      -dSplitDebugInfo="${SPLIT_DEBUG_INFO}"                                  \
      -dTrackWidgetCreation="${TRACK_WIDGET_CREATION}"                        \
      ${bundle_sksl_path}                                                     \
      ${code_size_directory}                                                  \
      --DartDefines="${DART_DEFINES}"                                         \
      --ExtraGenSnapshotOptions="${EXTRA_GEN_SNAPSHOT_OPTIONS}"               \
      --ExtraFrontEndOptions="${EXTRA_FRONT_END_OPTIONS}"                     \
      --build-inputs="${build_inputs_path}"                                   \
      --build-outputs="${build_outputs_path}"                                 \
      --output="${BUILT_PRODUCTS_DIR}"                                        \
     "${build_mode}_macos_bundle_flutter_assets"
}

# Adds the App.framework as an embedded binary and the flutter_assets as
# resources.
EmbedFrameworks() {
  # Embed App.framework from Flutter into the app (after creating the Frameworks directory
  # if it doesn't already exist).
  local xcode_frameworks_dir="${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
  RunCommand mkdir -p -- "${xcode_frameworks_dir}"
  RunCommand rsync -av --delete --filter "- .DS_Store" "${BUILT_PRODUCTS_DIR}/App.framework" "${xcode_frameworks_dir}"

  # Embed the actual FlutterMacOS.framework that the Flutter app expects to run against,
  # which could be a local build or an arch/type specific build.

  # Copy Xcode behavior and don't copy over headers or modules.
  RunCommand rsync -av --delete --filter "- .DS_Store" --filter "- Headers" --filter "- Modules" "${BUILT_PRODUCTS_DIR}/FlutterMacOS.framework" "${xcode_frameworks_dir}/"

  # Sign the binaries we moved.
  if [[ -n "${EXPANDED_CODE_SIGN_IDENTITY:-}" ]]; then
    RunCommand codesign --force --verbose --sign "${EXPANDED_CODE_SIGN_IDENTITY}" -- "${xcode_frameworks_dir}/App.framework/App"
    RunCommand codesign --force --verbose --sign "${EXPANDED_CODE_SIGN_IDENTITY}" -- "${xcode_frameworks_dir}/FlutterMacOS.framework/FlutterMacOS"
  fi
}

# Main entry point.
if [[ $# == 0 ]]; then
  # Unnamed entry point defaults to build.
  BuildApp
else
  case $1 in
    "build")
      BuildApp ;;
    "embed")
      EmbedFrameworks ;;
  esac
fi
