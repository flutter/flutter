// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

void runCommand() {
  //if [[ -n "$VERBOSE_SCRIPT_LOGGING" ]]; then
  //  echo "♦ $*"
  //fi
  //"$@"
  //return $?
}

// When provided with a pipe by the host Flutter build process, output to the
// pipe goes to stdout of the Flutter build process directly.
void streamOutput(String output) {
  //if [[ -n "$SCRIPT_OUTPUT_STREAM_FILE" ]]; then
  //  echo "$1" > $SCRIPT_OUTPUT_STREAM_FILE
  //fi
}

void assertExists(String filePath) {
  //if [[ ! -e "$1" ]]; then
  //  if [[ -h "$1" ]]; then
  //    EchoError "The path $1 is a symlink to a path that does not exist"
  //  else
  //    EchoError "The path $1 does not exist"
  //  fi
  //  exit -1
  //fi
  //return 0
}

void parseFlutterBuildMode() {
  //# Use FLUTTER_BUILD_MODE if it's set, otherwise use the Xcode build configuration name
  //# This means that if someone wants to use an Xcode build config other than Debug/Profile/Release,
  //# they _must_ set FLUTTER_BUILD_MODE so we know what type of artifact to build.
  //local build_mode="$(echo "${FLUTTER_BUILD_MODE:-${CONFIGURATION}}" | tr "[:upper:]" "[:lower:]")"

  //case "$build_mode" in
  //  *release*) build_mode="release";;
  //  *profile*) build_mode="profile";;
  //  *debug*) build_mode="debug";;
  //  *)
  //    EchoError "========================================================================"
  //    EchoError "ERROR: Unknown FLUTTER_BUILD_MODE: ${build_mode}."
  //    EchoError "Valid values are 'Debug', 'Profile', or 'Release' (case insensitive)."
  //    EchoError "This is controlled by the FLUTTER_BUILD_MODE environment variable."
  //    EchoError "If that is not set, the CONFIGURATION environment variable is used."
  //    EchoError ""
  //    EchoError "You can fix this by either adding an appropriately named build"
  //    EchoError "configuration, or adding an appropriate value for FLUTTER_BUILD_MODE to the"
  //    EchoError ".xcconfig file for the current build configuration (${CONFIGURATION})."
  //    EchoError "========================================================================"
  //    exit -1;;
  //esac
  //echo "${build_mode}"
}

//#Adds the App.framework as an embedded binary and the flutter_assets as
//#resources.
void embedFlutterFrameworks() {
  //# Embed App.framework from Flutter into the app (after creating the Frameworks directory
  //# if it doesn't already exist).
  //local xcode_frameworks_dir="${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
  //RunCommand mkdir -p -- "${xcode_frameworks_dir}"
  //RunCommand rsync -av --delete --filter "- .DS_Store" "${BUILT_PRODUCTS_DIR}/App.framework" "${xcode_frameworks_dir}"

  //# Embed the actual Flutter.framework that the Flutter app expects to run against,
  //# which could be a local build or an arch/type specific build.
  //RunCommand rsync -av --delete --filter "- .DS_Store" "${BUILT_PRODUCTS_DIR}/Flutter.framework" "${xcode_frameworks_dir}/"

  //AddObservatoryBonjourService
}

//# Add the observatory publisher Bonjour service to the produced app bundle Info.plist.
void addObservatoryBonjourService() {
  //local build_mode="$(ParseFlutterBuildMode)"
  //# Debug and profile only.
  //if [[ "${build_mode}" == "release" ]]; then
  //  return
  //fi
  //local built_products_plist="${BUILT_PRODUCTS_DIR}/${INFOPLIST_PATH}"

  //if [[ ! -f "${built_products_plist}" ]]; then
  //  # Very occasionally Xcode hasn't created an Info.plist when this runs.
  //  # The file will be present on re-run.
  //  echo "${INFOPLIST_PATH} does not exist. Skipping _dartobservatory._tcp NSBonjourServices insertion. Try re-building to enable \"flutter attach\"."
  //  return
  //fi
  //# If there are already NSBonjourServices specified by the app (uncommon), insert the observatory service name to the existing list.
  //if plutil -extract NSBonjourServices xml1 -o - "${built_products_plist}"; then
  //  RunCommand plutil -insert NSBonjourServices.0 -string "_dartobservatory._tcp" "${built_products_plist}"
  //else
  //  # Otherwise, add the NSBonjourServices key and observatory service name.
  //  RunCommand plutil -insert NSBonjourServices -json "[\"_dartobservatory._tcp\"]" "${built_products_plist}"
  //fi

  //# Don't override the local network description the Flutter app developer specified (uncommon).
  //# This text will appear below the "Your app would like to find and connect to devices on your local network" permissions popup.
  //if ! plutil -extract NSLocalNetworkUsageDescription xml1 -o - "${built_products_plist}"; then
  //  RunCommand plutil -insert NSLocalNetworkUsageDescription -string "Allow Flutter tools on your computer to connect and debug your application. This prompt will not appear on release builds." "${built_products_plist}"
  //fi
}

// Main entry point.
void main(List<String> arguments) {
  Context(
    arguments: arguments,
    environment: Platform.environment,
  ).run();
}

class Context {
  Context({
    required this.arguments,
    required this.environment,
  });

  final Map<String, String> environment;
  final List<String> arguments;

  // Main execution.
  void run() {
    // $# is number of arguments
    //if [[ $# == 0 ]]; then
    if (arguments.isEmpty) {
      // Named entry points were introduced in Flutter v0.0.7.
      //  EchoError "error: Your Xcode project is incompatible with this version of Flutter. Run \"rm -rf ios/Runner.xcodeproj\" and \"flutter create .\" to regenerate."
      stderr.write(
          'error: Your Xcode project is incompatible with this version of Flutter. '
          'Run "rm -rf ios/Runner.xcodeproj" and "flutter create ." to regenerate.\n');
      //  exit -1
      exit(-1);
    }

    final String subCommand = arguments.first;
    //  case $1 in
    switch (subCommand) {
      //    "build")
      //      BuildApp ;;
      case 'build':
        buildApp();
        break;
        //    "thin")
      case 'thin':
        // No-op, thinning is handled during the bundle asset assemble build target.
        break;
        //    "embed")
      case 'embed':
        //      EmbedFlutterFrameworks ;;
        embedFlutterFrameworks();
        break;
        //    "embed_and_thin")
      case 'embed_and_thin':
        // Thinning is handled during the bundle asset assemble build target, so just embed.
        //      EmbedFlutterFrameworks ;;
        embedFlutterFrameworks();
        break;
        //    "test_observatory_bonjour_service")
      case 'test_observatory_bonjour_service':
        // Exposed for integration testing only.
        //      AddObservatoryBonjourService ;;
        addObservatoryBonjourService();
    }
  }

  bool existsDir(String path) {
    final Directory dir = Directory(path);
    return dir.existsSync();
  }

  void buildApp() {
    final String sourceRoot = environment['SOURCE_ROOT'] ?? '';
    //local project_path="${SOURCE_ROOT}/.."
    String projectPath = '$sourceRoot/..';
    //if [[ -n "$FLUTTER_APPLICATION_PATH" ]]; then
    if (environment['FLUTTER_APPLICATION_PATH'] != null) {
      //  project_path="${FLUTTER_APPLICATION_PATH}"
      projectPath = environment['FLUTTER_APPLICATION_PATH']!;
      //fi
    }

    //local target_path="lib/main.dart"
    String targetPath = 'lib/main.dart';
    //if [[ -n "$FLUTTER_TARGET" ]]; then
    if (environment['FLUTTER_TARGET'] != null) {
      //  target_path="${FLUTTER_TARGET}"
      targetPath = environment['FLUTTER_TARGET']!;
      //fi
    }

    //local derived_dir="${SOURCE_ROOT}/Flutter"
    String derivedDir = '$sourceRoot/Flutter}';
    //if [[ -e "${project_path}/.ios" ]]; then
    if (existsDir('$projectPath/.ios')) {
      //  derived_dir="${project_path}/.ios/Flutter"
      derivedDir = '$projectPath/.ios/Flutter';
      //fi
    }

    // Default value of assets_path is flutter_assets
    //local assets_path="flutter_assets"
    String assetsPath = 'flutter_assets';
    // The value of assets_path can set by add FLTAssetsPath to
    // AppFrameworkInfo.plist.
    //if FLTAssetsPath=$(/usr/libexec/PlistBuddy -c "Print :FLTAssetsPath" "${derived_dir}/AppFrameworkInfo.plist" 2>/dev/null); then
    //  if [[ -n "$FLTAssetsPath" ]]; then
    //    assets_path="${FLTAssetsPath}"
    //  fi
    //fi

    //# Use FLUTTER_BUILD_MODE if it's set, otherwise use the Xcode build configuration name
    //# This means that if someone wants to use an Xcode build config other than Debug/Profile/Release,
    //# they _must_ set FLUTTER_BUILD_MODE so we know what type of artifact to build.
    //local build_mode="$(ParseFlutterBuildMode)"
    //local artifact_variant="unknown"
    //case "$build_mode" in
    //  release ) artifact_variant="ios-release";;
    //  profile ) artifact_variant="ios-profile";;
    //  debug ) artifact_variant="ios";;
    //esac

    //# Warn the user if not archiving (ACTION=install) in release mode.
    //if [[ "$ACTION" == "install" && "$build_mode" != "release" ]]; then
    //  echo "warning: Flutter archive not built in Release mode. Ensure FLUTTER_BUILD_MODE \
    // is set to release or run \"flutter build ios --release\", then re-run Archive from Xcode."
    //fi

    //local framework_path="${FLUTTER_ROOT}/bin/cache/artifacts/engine/${artifact_variant}"
    //local flutter_framework="${framework_path}/Flutter.xcframework"

    //if [[ -n "$LOCAL_ENGINE" ]]; then
    //  if [[ $(echo "$LOCAL_ENGINE" | tr "[:upper:]" "[:lower:]") != *"$build_mode"* ]]; then
    //    EchoError "========================================================================"
    //    EchoError "ERROR: Requested build with Flutter local engine at '${LOCAL_ENGINE}'"
    //    EchoError "This engine is not compatible with FLUTTER_BUILD_MODE: '${build_mode}'."
    //    EchoError "You can fix this by updating the LOCAL_ENGINE environment variable, or"
    //    EchoError "by running:"
    //    EchoError "  flutter build ios --local-engine=ios_${build_mode}"
    //    EchoError "or"
    //    EchoError "  flutter build ios --local-engine=ios_${build_mode}_unopt"
    //    EchoError "========================================================================"
    //    exit -1
    //  fi
    //  flutter_framework="${FLUTTER_ENGINE}/out/${LOCAL_ENGINE}/Flutter.xcframework"
    //fi
    //local bitcode_flag=""
    //if [[ "$ENABLE_BITCODE" == "YES" && "$ACTION" == "install" ]]; then
    //  bitcode_flag="true"
    //fi

    //# TODO(jmagman): use assemble copied engine in add-to-app.
    //if [[ -e "${project_path}/.ios" ]]; then
    //  RunCommand rsync -av --delete --filter "- .DS_Store" "${flutter_framework}" "${derived_dir}/engine"
    //fi

    //RunCommand pushd "${project_path}" > /dev/null

    //# Construct the "flutter assemble" argument array. Arguments should be added
    //# as quoted string elements of the flutter_args array, otherwise an argument
    //# (like a path) with spaces in it might be interpreted as two separate
    //# arguments.
    //local flutter_args=("${FLUTTER_ROOT}/bin/flutter")
    //if [[ -n "$VERBOSE_SCRIPT_LOGGING" ]]; then
    //  flutter_args+=('--verbose')
    //fi
    //if [[ -n "$FLUTTER_ENGINE" ]]; then
    //  flutter_args+=("--local-engine-src-path=${FLUTTER_ENGINE}")
    //fi
    //if [[ -n "$LOCAL_ENGINE" ]]; then
    //  flutter_args+=("--local-engine=${LOCAL_ENGINE}")
    //fi
    //flutter_args+=(
    //  "assemble"
    //  "--no-version-check"
    //  "--output=${BUILT_PRODUCTS_DIR}/"
    //  "-dTargetPlatform=ios"
    //  "-dTargetFile=${target_path}"
    //  "-dBuildMode=${build_mode}"
    //  "-dIosArchs=${ARCHS}"
    //  "-dSdkRoot=${SDKROOT}"
    //  "-dSplitDebugInfo=${SPLIT_DEBUG_INFO}"
    //  "-dTreeShakeIcons=${TREE_SHAKE_ICONS}"
    //  "-dTrackWidgetCreation=${TRACK_WIDGET_CREATION}"
    //  "-dDartObfuscation=${DART_OBFUSCATION}"
    //  "-dEnableBitcode=${bitcode_flag}"
    //  "--ExtraGenSnapshotOptions=${EXTRA_GEN_SNAPSHOT_OPTIONS}"
    //  "--DartDefines=${DART_DEFINES}"
    //  "--ExtraFrontEndOptions=${EXTRA_FRONT_END_OPTIONS}"
    //)
    //if [[ -n "$PERFORMANCE_MEASUREMENT_FILE" ]]; then
    //  flutter_args+=("--performance-measurement-file=${PERFORMANCE_MEASUREMENT_FILE}")
    //fi
    //if [[ -n "${EXPANDED_CODE_SIGN_IDENTITY:-}" && "${CODE_SIGNING_REQUIRED:-}" != "NO" ]]; then
    //  flutter_args+=("-dCodesignIdentity=${EXPANDED_CODE_SIGN_IDENTITY}")
    //fi
    //if [[ -n "$BUNDLE_SKSL_PATH" ]]; then
    //  flutter_args+=("-dBundleSkSLPath=${BUNDLE_SKSL_PATH}")
    //fi
    //if [[ -n "$CODE_SIZE_DIRECTORY" ]]; then
    //  flutter_args+=("-dCodeSizeDirectory=${CODE_SIZE_DIRECTORY}")
    //fi
    //flutter_args+=("${build_mode}_ios_bundle_flutter_assets")

    //RunCommand "${flutter_args[@]}"

    //if [[ $? -ne 0 ]]; then
    //  EchoError "Failed to package ${project_path}."
    //  exit -1
    //fi
    //StreamOutput "done"
    //StreamOutput " └─Compiling, linking and signing..."

    //RunCommand popd > /dev/null

    //echo "Project ${project_path} built and packaged successfully."
    //return 0
  }
}


