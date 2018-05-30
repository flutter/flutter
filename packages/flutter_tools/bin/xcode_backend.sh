#!/bin/bash
# Copyright 2016 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

RunCommand() {
  if [[ -n "$VERBOSE_SCRIPT_LOGGING" ]]; then
    echo "♦ $*"
  fi
  "$@"
  return $?
}

# When provided with a pipe by the host Flutter build process, output to the
# pipe goes to stdout of the Flutter build process directly.
StreamOutput() {
  if [[ -n "$SCRIPT_OUTPUT_STREAM_FILE" ]]; then
    echo "$1" > $SCRIPT_OUTPUT_STREAM_FILE
  fi
}

EchoError() {
  echo "$@" 1>&2
}

AssertExists() {
  if [[ ! -e "$1" ]]; then
    if [[ -h "$1" ]]; then
      EchoError "The path $1 is a symlink to a path that does not exist"
    else
      EchoError "The path $1 does not exist"
    fi
    exit -1
  fi
  return 0
}

BuildApp() {
  local project_path="${SOURCE_ROOT}/.."
  if [[ -n "$FLUTTER_APPLICATION_PATH" ]]; then
    project_path="${FLUTTER_APPLICATION_PATH}"
  fi

  local target_path="lib/main.dart"
  if [[ -n "$FLUTTER_TARGET" ]]; then
    target_path="${FLUTTER_TARGET}"
  fi

  # Archive builds (ACTION=install) should always run in release mode.
  if [[ "$ACTION" == "install" && "$FLUTTER_BUILD_MODE" != "release" ]]; then
    EchoError "========================================================================"
    EchoError "ERROR: Flutter archive builds must be run in Release mode."
    EchoError ""
    EchoError "To correct, run:"
    EchoError "flutter build ios --release"
    EchoError ""
    EchoError "then re-run Archive from Xcode."
    EchoError "========================================================================"
    exit -1
  fi

  local build_mode="release"
  if [[ -n "$FLUTTER_BUILD_MODE" ]]; then
    build_mode="${FLUTTER_BUILD_MODE}"
  fi

  local artifact_variant="unknown"
  case "$build_mode" in
    release) artifact_variant="ios-release";;
    profile) artifact_variant="ios-profile";;
    debug) artifact_variant="ios";;
    *) echo "Unknown FLUTTER_BUILD_MODE: $FLUTTER_BUILD_MODE";;
  esac

  local framework_path="${FLUTTER_ROOT}/bin/cache/artifacts/engine/${artifact_variant}"
  if [[ -n "$FLUTTER_FRAMEWORK_DIR" ]]; then
    framework_path="${FLUTTER_FRAMEWORK_DIR}"
  fi

  AssertExists "${project_path}"

  local derived_dir="${SOURCE_ROOT}/Flutter"
  RunCommand mkdir -p -- "$derived_dir"
  AssertExists "$derived_dir"

  RunCommand rm -rf -- "${derived_dir}/Flutter.framework"
  RunCommand rm -rf -- "${derived_dir}/App.framework"
  RunCommand cp -r -- "${framework_path}/Flutter.framework" "${derived_dir}"
  RunCommand find "${derived_dir}/Flutter.framework" -type f -exec chmod a-w "{}" \;
  RunCommand pushd "${project_path}" > /dev/null

  AssertExists "${target_path}"

  local verbose_flag=""
  if [[ -n "$VERBOSE_SCRIPT_LOGGING" ]]; then
    verbose_flag="--verbose"
  fi

  local build_dir="${FLUTTER_BUILD_DIR:-build}"
  local local_engine_flag=""
  if [[ -n "$LOCAL_ENGINE" ]]; then
    local_engine_flag="--local-engine=$LOCAL_ENGINE"
  fi

  local preview_dart_2_flag=""
  if [[ -n "$PREVIEW_DART_2" ]]; then
    preview_dart_2_flag="--preview-dart-2"
  else
    preview_dart_2_flag="--no-preview-dart-2"
  fi

  if [[ "${build_mode}" != "debug" ]]; then
    StreamOutput " ├─Building Dart code..."
    # Transform ARCHS to comma-separated list of target architectures.
    local archs="${ARCHS// /,}"
    RunCommand "${FLUTTER_ROOT}/bin/flutter" --suppress-analytics           \
      ${verbose_flag}                                                       \
      build aot                                                             \
      --output-dir="${build_dir}/aot"                                       \
      --target-platform=ios                                                 \
      --target="${target_path}"                                             \
      --${build_mode}                                                       \
      --ios-arch="${archs}"                                                 \
      ${local_engine_flag}                                                  \
      ${preview_dart_2_flag}

    if [[ $? -ne 0 ]]; then
      EchoError "Failed to build ${project_path}."
      exit -1
    fi
    StreamOutput "done"

    RunCommand cp -r -- "${build_dir}/aot/App.framework" "${derived_dir}"
  else
    RunCommand mkdir -p -- "${derived_dir}/App.framework"

    # Build stub for all requested architectures.
    local arch_flags=""
    read -r -a archs <<< "$ARCHS"
    for arch in "${archs[@]}"; do
      arch_flags="${arch_flags}-arch $arch "
    done

    RunCommand eval "$(echo "static const int Moo = 88;" | xcrun clang -x c \
        ${arch_flags} \
        -dynamiclib \
        -Xlinker -rpath -Xlinker '@executable_path/Frameworks' \
        -Xlinker -rpath -Xlinker '@loader_path/Frameworks' \
        -install_name '@rpath/App.framework/App' \
        -o "${derived_dir}/App.framework/App" -)"
  fi
  RunCommand cp -- "${derived_dir}/AppFrameworkInfo.plist" "${derived_dir}/App.framework/Info.plist"

  local precompilation_flag=""
  if [[ "$CURRENT_ARCH" != "x86_64" ]] && [[ "$build_mode" != "debug" ]]; then
    precompilation_flag="--precompiled"
  fi

  StreamOutput " ├─Assembling Flutter resources..."
  RunCommand "${FLUTTER_ROOT}/bin/flutter" --suppress-analytics             \
    ${verbose_flag}                                                         \
    build bundle                                                            \
    --target="${target_path}"                                               \
    --snapshot="${build_dir}/snapshot_blob.bin"                             \
    --depfile="${build_dir}/snapshot_blob.bin.d"                            \
    --asset-dir="${derived_dir}/flutter_assets"                             \
    ${precompilation_flag}                                                  \
    ${local_engine_flag}                                                    \
    ${preview_dart_2_flag}

  if [[ $? -ne 0 ]]; then
    EchoError "Failed to package ${project_path}."
    exit -1
  fi
  StreamOutput "done"
  StreamOutput " └─Compiling, linking and signing..."

  RunCommand popd > /dev/null

  echo "Project ${project_path} built and packaged successfully."
  return 0
}

# Returns the CFBundleExecutable for the specified framework directory.
GetFrameworkExecutablePath() {
  local framework_dir="$1"

  local plist_path="${framework_dir}/Info.plist"
  local executable="$(defaults read "${plist_path}" CFBundleExecutable)"
  echo "${framework_dir}/${executable}"
}

# Destructively thins the specified executable file to include only the
# specified architectures.
LipoExecutable() {
  local executable="$1"
  shift
  # Split $@ into an array.
  read -r -a archs <<< "$@"

  # Extract architecture-specific framework executables.
  local all_executables=()
  for arch in "${archs[@]}"; do
    local output="${executable}_${arch}"
    local lipo_info="$(lipo -info "${executable}")"
    if [[ "${lipo_info}" == "Non-fat file:"* ]]; then
      if [[ "${lipo_info}" != *"${arch}" ]]; then
        echo "Non-fat binary ${executable} is not ${arch}. Running lipo -info:"
        echo "${lipo_info}"
        exit 1
      fi
    else
      lipo -output "${output}" -extract "${arch}" "${executable}"
      if [[ $? == 0 ]]; then
        all_executables+=("${output}")
      else
        echo "Failed to extract ${arch} for ${executable}. Running lipo -info:"
        lipo -info "${executable}"
        exit 1
      fi
    fi
  done

  # Generate a merged binary from the architecture-specific executables.
  # Skip this step for non-fat executables.
  if [[ ${#all_executables[@]} > 0 ]]; then
    local merged="${executable}_merged"
    lipo -output "${merged}" -create "${all_executables[@]}"

    cp -f -- "${merged}" "${executable}" > /dev/null
    rm -f -- "${merged}" "${all_executables[@]}"
  fi
}

# Destructively thins the specified framework to include only the specified
# architectures.
ThinFramework() {
  local framework_dir="$1"
  shift

  local plist_path="${framework_dir}/Info.plist"
  local executable="$(GetFrameworkExecutablePath "${framework_dir}")"
  LipoExecutable "${executable}" "$@"
}

ThinAppFrameworks() {
  local app_path="${TARGET_BUILD_DIR}/${WRAPPER_NAME}"
  local frameworks_dir="${app_path}/Frameworks"

  [[ -d "$frameworks_dir" ]] || return 0
  find "${app_path}" -type d -name "*.framework" | while read framework_dir; do
    ThinFramework "$framework_dir" "$ARCHS"
  done
}

# Main entry point.

# TODO(cbracken) improve error handling, then enable set -e

if [[ $# == 0 ]]; then
  # Backwards-compatibility: if no args are provided, build.
  BuildApp
else
  case $1 in
    "build")
      BuildApp ;;
    "thin")
      ThinAppFrameworks ;;
  esac
fi
