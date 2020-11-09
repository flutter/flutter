#!/usr/bin/env bash
# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Exit on error
set -e

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

ParseFlutterBuildMode() {
  # Use FLUTTER_BUILD_MODE if it's set, otherwise use the Xcode build configuration name
  # This means that if someone wants to use an Xcode build config other than Debug/Profile/Release,
  # they _must_ set FLUTTER_BUILD_MODE so we know what type of artifact to build.
  local build_mode="$(echo "${FLUTTER_BUILD_MODE:-${CONFIGURATION}}" | tr "[:upper:]" "[:lower:]")"

  case "$build_mode" in
    *release*) build_mode="release";;
    *profile*) build_mode="profile";;
    *debug*) build_mode="debug";;
    *)
      EchoError "========================================================================"
      EchoError "ERROR: Unknown FLUTTER_BUILD_MODE: ${build_mode}."
      EchoError "Valid values are 'Debug', 'Profile', or 'Release' (case insensitive)."
      EchoError "This is controlled by the FLUTTER_BUILD_MODE environment variable."
      EchoError "If that is not set, the CONFIGURATION environment variable is used."
      EchoError ""
      EchoError "You can fix this by either adding an appropriately named build"
      EchoError "configuration, or adding an appropriate value for FLUTTER_BUILD_MODE to the"
      EchoError ".xcconfig file for the current build configuration (${CONFIGURATION})."
      EchoError "========================================================================"
      exit -1;;
  esac
  echo "${build_mode}"
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

  local derived_dir="${SOURCE_ROOT}/Flutter"
  if [[ -e "${project_path}/.ios" ]]; then
    derived_dir="${project_path}/.ios/Flutter"
  fi

  local bundle_sksl_path=""
  if [[ -n "$BUNDLE_SKSL_PATH" ]]; then
    bundle_sksl_path="-iBundleSkSLPath=${BUNDLE_SKSL_PATH}"
  fi

  # Default value of assets_path is flutter_assets
  local assets_path="flutter_assets"
  # The value of assets_path can set by add FLTAssetsPath to
  # AppFrameworkInfo.plist.
  if FLTAssetsPath=$(/usr/libexec/PlistBuddy -c "Print :FLTAssetsPath" "${derived_dir}/AppFrameworkInfo.plist" 2>/dev/null); then
    if [[ -n "$FLTAssetsPath" ]]; then
      assets_path="${FLTAssetsPath}"
    fi
  fi

  # Use FLUTTER_BUILD_MODE if it's set, otherwise use the Xcode build configuration name
  # This means that if someone wants to use an Xcode build config other than Debug/Profile/Release,
  # they _must_ set FLUTTER_BUILD_MODE so we know what type of artifact to build.
  local build_mode="$(ParseFlutterBuildMode)"
  local artifact_variant="unknown"
  case "$build_mode" in
    release ) artifact_variant="ios-release";;
    profile ) artifact_variant="ios-profile";;
    debug ) artifact_variant="ios";;
  esac

  # Warn the user if not archiving (ACTION=install) in release mode.
  if [[ "$ACTION" == "install" && "$build_mode" != "release" ]]; then
    echo "warning: Flutter archive not built in Release mode. Ensure FLUTTER_BUILD_MODE \
is set to release or run \"flutter build ios --release\", then re-run Archive from Xcode."
  fi

  local framework_path="${FLUTTER_ROOT}/bin/cache/artifacts/engine/${artifact_variant}"
  local flutter_engine_flag=""
  local local_engine_flag=""
  local flutter_framework="${framework_path}/Flutter.framework"
  local flutter_podspec="${framework_path}/Flutter.podspec"

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
      EchoError "  flutter build ios --local-engine=ios_${build_mode}"
      EchoError "or"
      EchoError "  flutter build ios --local-engine=ios_${build_mode}_unopt"
      EchoError "========================================================================"
      exit -1
    fi
    local_engine_flag="--local-engine=${LOCAL_ENGINE}"
    flutter_framework="${FLUTTER_ENGINE}/out/${LOCAL_ENGINE}/Flutter.framework"
    flutter_podspec="${FLUTTER_ENGINE}/out/${LOCAL_ENGINE}/Flutter.podspec"
  fi

  local bitcode_flag=""
  if [[ "$ENABLE_BITCODE" == "YES" ]]; then
    bitcode_flag="true"
  fi

  # TODO(jonahwilliams): move engine copying to build system.
  if [[ -e "${project_path}/.ios" ]]; then
    RunCommand rm -rf -- "${derived_dir}/engine"
    mkdir "${derived_dir}/engine"
    RunCommand cp -r -- "${flutter_podspec}" "${derived_dir}/engine"
    RunCommand cp -r -- "${flutter_framework}" "${derived_dir}/engine"
  else
    RunCommand rm -rf -- "${derived_dir}/Flutter.framework"
    RunCommand cp -- "${flutter_podspec}" "${derived_dir}"
    RunCommand cp -r -- "${flutter_framework}" "${derived_dir}"
  fi

  RunCommand pushd "${project_path}" > /dev/null

  local verbose_flag=""
  if [[ -n "$VERBOSE_SCRIPT_LOGGING" ]]; then
    verbose_flag="--verbose"
  fi

  local performance_measurement_option=""
  if [[ -n "$PERFORMANCE_MEASUREMENT_FILE" ]]; then
    performance_measurement_option="--performance-measurement-file=${PERFORMANCE_MEASUREMENT_FILE}"
  fi

  local code_size_directory=""
  if [[ -n "$CODE_SIZE_DIRECTORY" ]]; then
    code_size_directory="-dCodeSizeDirectory=${CODE_SIZE_DIRECTORY}"
  fi

  RunCommand "${FLUTTER_ROOT}/bin/flutter"                                \
    ${verbose_flag}                                                       \
    ${flutter_engine_flag}                                                \
    ${local_engine_flag}                                                  \
    assemble                                                              \
    --output="${derived_dir}/"                                            \
    ${performance_measurement_option}                                     \
    -dTargetPlatform=ios                                                  \
    -dTargetFile="${target_path}"                                         \
    -dBuildMode=${build_mode}                                             \
    -dIosArchs="${ARCHS}"                                                 \
    -dSplitDebugInfo="${SPLIT_DEBUG_INFO}"                                \
    -dTreeShakeIcons="${TREE_SHAKE_ICONS}"                                \
    -dTrackWidgetCreation="${TRACK_WIDGET_CREATION}"                      \
    -dDartObfuscation="${DART_OBFUSCATION}"                               \
    -dEnableBitcode="${bitcode_flag}"                                     \
    ${bundle_sksl_path}                                                   \
    ${code_size_directory}                                                \
    --ExtraGenSnapshotOptions="${EXTRA_GEN_SNAPSHOT_OPTIONS}"             \
    --DartDefines="${DART_DEFINES}"                                       \
    --ExtraFrontEndOptions="${EXTRA_FRONT_END_OPTIONS}"                   \
    "${build_mode}_ios_bundle_flutter_assets"

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
      if lipo -output "${output}" -extract "${arch}" "${executable}"; then
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

# Adds the App.framework as an embedded binary and the flutter_assets as
# resources.
EmbedFlutterFrameworks() {
  local project_path="${SOURCE_ROOT}/.."
  if [[ -n "$FLUTTER_APPLICATION_PATH" ]]; then
    project_path="${FLUTTER_APPLICATION_PATH}"
  fi

  # Prefer the hidden .ios folder, but fallback to a visible ios folder if .ios
  # doesn't exist.
  local flutter_ios_out_folder="${project_path}/.ios/Flutter"
  local flutter_ios_engine_folder="${project_path}/.ios/Flutter/engine"
  if [[ ! -d ${flutter_ios_out_folder} ]]; then
    flutter_ios_out_folder="${project_path}/ios/Flutter"
    flutter_ios_engine_folder="${project_path}/ios/Flutter"
  fi

  AssertExists "${flutter_ios_out_folder}"

  # Embed App.framework from Flutter into the app (after creating the Frameworks directory
  # if it doesn't already exist).
  local xcode_frameworks_dir="${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
  RunCommand mkdir -p -- "${xcode_frameworks_dir}"
  RunCommand rsync -av --delete "${flutter_ios_out_folder}/App.framework" "${xcode_frameworks_dir}"

  # Embed the actual Flutter.framework that the Flutter app expects to run against,
  # which could be a local build or an arch/type specific build.

  # Copy Xcode behavior and don't copy over headers or modules.
  RunCommand rsync -av --delete --filter "- .DS_Store/" --filter "- Headers/" --filter "- Modules/" "${flutter_ios_engine_folder}/Flutter.framework" "${xcode_frameworks_dir}/"
  if [[ "$ACTION" != "install" || "$ENABLE_BITCODE" == "NO" ]]; then
    # Strip bitcode from the destination unless archiving, or if bitcode is disabled entirely.
    RunCommand "${DT_TOOLCHAIN_DIR}"/usr/bin/bitcode_strip "${flutter_ios_engine_folder}/Flutter.framework/Flutter" -r -o "${xcode_frameworks_dir}/Flutter.framework/Flutter"
  fi

  # Sign the binaries we moved.
  if [[ -n "${EXPANDED_CODE_SIGN_IDENTITY:-}" ]]; then
    RunCommand codesign --force --verbose --sign "${EXPANDED_CODE_SIGN_IDENTITY}" -- "${xcode_frameworks_dir}/App.framework/App"
    RunCommand codesign --force --verbose --sign "${EXPANDED_CODE_SIGN_IDENTITY}" -- "${xcode_frameworks_dir}/Flutter.framework/Flutter"
  fi

  AddObservatoryBonjourService
}

# Add the observatory publisher Bonjour service to the produced app bundle Info.plist.
AddObservatoryBonjourService() {
  local build_mode="$(ParseFlutterBuildMode)"
  # Debug and profile only.
  if [[ "${build_mode}" == "release" ]]; then
    return
  fi
  local built_products_plist="${BUILT_PRODUCTS_DIR}/${INFOPLIST_PATH}"

  if [[ ! -f "${built_products_plist}" ]]; then
    EchoError "error: ${INFOPLIST_PATH} does not exist. The Flutter \"Thin Binary\" build phase must run after \"Copy Bundle Resources\"."
    exit -1
  fi
  # If there are already NSBonjourServices specified by the app (uncommon), insert the observatory service name to the existing list.
  if plutil -extract NSBonjourServices xml1 -o - "${built_products_plist}"; then
    RunCommand plutil -insert NSBonjourServices.0 -string "_dartobservatory._tcp" "${built_products_plist}"
  else
    # Otherwise, add the NSBonjourServices key and observatory service name.
    RunCommand plutil -insert NSBonjourServices -json "[\"_dartobservatory._tcp\"]" "${built_products_plist}"
  fi

  # Don't override the local network description the Flutter app developer specified (uncommon).
  # This text will appear below the "Your app would like to find and connect to devices on your local network" permissions popup.
  if ! plutil -extract NSLocalNetworkUsageDescription xml1 -o - "${built_products_plist}"; then
    RunCommand plutil -insert NSLocalNetworkUsageDescription -string "Allow Flutter tools on your computer to connect and debug your application. This prompt will not appear on release builds." "${built_products_plist}"
  fi
}

EmbedAndThinFrameworks() {
  EmbedFlutterFrameworks
  ThinAppFrameworks
}

# Main entry point.
if [[ $# == 0 ]]; then
  # Named entry points were introduced in Flutter v0.0.7.
  EchoError "error: Your Xcode project is incompatible with this version of Flutter. Run \"rm -rf ios/Runner.xcodeproj\" and \"flutter create .\" to regenerate."
  exit -1
else
  case $1 in
    "build")
      BuildApp ;;
    "thin")
      ThinAppFrameworks ;;
    "embed")
      EmbedFlutterFrameworks ;;
    "embed_and_thin")
      EmbedAndThinFrameworks ;;
    "test_observatory_bonjour_service")
      # Exposed for integration testing only.
      AddObservatoryBonjourService ;;
  esac
fi
