// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

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
  }) {
    final String? scriptOutputStreamFileEnv = environment['SCRIPT_OUTPUT_STREAM_FILE'];
    if (scriptOutputStreamFileEnv != null && scriptOutputStreamFileEnv.isNotEmpty) {
      scriptOutputStreamFile = File(
        scriptOutputStreamFileEnv,
      ).openSync(mode: FileMode.write);
    }
  }

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

  bool existsFile(String path) {
    final File file = File(path);
    return file.existsSync();
  }

  /// Run given command in a synchronous subprocess.
  ///
  /// Will throw [Exception] if the exit code is not 0.
  ProcessResult runSync(
    String bin,
    List<String> args, {
    bool verbose = false,
    bool allowFail = false,
    String? workingDirectory,
  }) {
    if (verbose) {
      print('♦ $bin ${args.join(' ')}');
    }
    final ProcessResult result = Process.runSync(
      bin,
      args,
      workingDirectory: workingDirectory,
    );
    echo(result.stdout as String);
    if ((result.stderr as String).isNotEmpty) {
      echoError(result.stderr as String);
    }
    if (!allowFail && result.exitCode != 0) {
      stderr.write('${result.stderr}\n');
      throw Exception(
        'Command "$bin ${args.join(' ')}" exited with code ${result.exitCode}',
      );
    }
    return result;
  }

  void echoError(String message) {
    stderr.write('$message\n');
  }

  void echo(String message) {
    print(message);
  }

  Never exitApp(int code) {
    exit(code);
  }

  /// Return value from environment if it exists, else throw [Exception].
  String environmentEnsure(String key) {
    final String? value = environment[key];
    if (value == null) {
      throw Exception(
        'Expected the environment variable "$key" to exist, but it did not!',
      );
    }
    return value;
  }

  RandomAccessFile? scriptOutputStreamFile;

  // When provided with a pipe by the host Flutter build process, output to the
  // pipe goes to stdout of the Flutter build process directly.
  void streamOutput(String output) {
    //if [[ -n "$SCRIPT_OUTPUT_STREAM_FILE" ]]; then
    //  echo "$1" > $SCRIPT_OUTPUT_STREAM_FILE
    //fi
    scriptOutputStreamFile?.writeStringSync(output);
  }


  String parseFlutterBuildMode() {
    //# Use FLUTTER_BUILD_MODE if it's set, otherwise use the Xcode build configuration name
    //# This means that if someone wants to use an Xcode build config other than Debug/Profile/Release,
    //# they _must_ set FLUTTER_BUILD_MODE so we know what type of artifact to build.
    //local build_mode="$(echo "${FLUTTER_BUILD_MODE:-${CONFIGURATION}}" | tr "[:upper:]" "[:lower:]")"
    final String? buildMode = (environment['FLUTTER_BUILD_MODE'] ?? environment['CONFIGURATION'])?.toLowerCase();
    if (buildMode == null) {
      throw Exception(
        'could not determine buildMode from either FLUTTER_BUILD_MODE or '
        'CONFIGURATION environment variables');
    }

    //case "$build_mode" in
    //  *release*) build_mode="release";;
    if (buildMode.contains('release')) {
      return 'release';
    }
    //  *profile*) build_mode="profile";;
    if (buildMode.contains('profile')) {
      return 'profile';
    }
    //  *debug*) build_mode="debug";;
    if (buildMode.contains('debug')) {
      return 'debug';
    }
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
    echoError('========================================================================');
    echoError('ERROR: Unknown FLUTTER_BUILD_MODE: $buildMode.');
    echoError("Valid values are 'Debug', 'Profile', or 'Release' (case insensitive).");
    echoError('This is controlled by the FLUTTER_BUILD_MODE environment variable.');
    echoError('If that is not set, the CONFIGURATION environment variable is used.');
    echoError('');
    echoError('You can fix this by either adding an appropriately named build');
    echoError('configuration, or adding an appropriate value for FLUTTER_BUILD_MODE to the');
    echoError('.xcconfig file for the current build configuration (${environment['CONFIGURATION']}).');
    echoError('========================================================================');
    exitApp(-1);
    //esac
    //echo "${build_mode}"
  }

  //#Adds the App.framework as an embedded binary and the flutter_assets as
  //#resources.
  void embedFlutterFrameworks() {
    //# Embed App.framework from Flutter into the app (after creating the Frameworks directory
    //# if it doesn't already exist).
    //local xcode_frameworks_dir="${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
    final String xcodeFrameworksDir = '${environment['TARGET_BUILD_DIR']}/${environment['FRAMEWORKS_FOLDER_PATH']}';
    //RunCommand mkdir -p -- "${xcode_frameworks_dir}"
    runSync(
      'mkdir',
      <String>[
        '-p',
        '--',
        xcodeFrameworksDir,
      ]
    );
    //RunCommand rsync -av --delete --filter "- .DS_Store" "${BUILT_PRODUCTS_DIR}/App.framework" "${xcode_frameworks_dir}"
    runSync(
      'rsync',
      <String>[
        '-av',
        '--delete',
        '--filter',
        '- .DS_Store',
        '${environment['BUILT_PRODUCTS_DIR']}/App.framework',
        xcodeFrameworksDir,
      ],
    );

    //# Embed the actual Flutter.framework that the Flutter app expects to run against,
    //# which could be a local build or an arch/type specific build.
    //RunCommand rsync -av --delete --filter "- .DS_Store" "${BUILT_PRODUCTS_DIR}/Flutter.framework" "${xcode_frameworks_dir}/"
    runSync(
      'rsync',
      <String>[
        '-av',
        '--delete',
        '--filter',
        '- .DS_Store',
        '${environment['BUILT_PRODUCTS_DIR']}/Flutter.framework',
        '$xcodeFrameworksDir/',
      ],
    );

    //AddObservatoryBonjourService
  }

  //# Add the observatory publisher Bonjour service to the produced app bundle Info.plist.
  void addObservatoryBonjourService() {
    //local build_mode="$(ParseFlutterBuildMode)"
    final String buildMode = parseFlutterBuildMode();

    //# Debug and profile only.
    //if [[ "${build_mode}" == "release" ]]; then
    //  return
    //fi
    if (buildMode == 'release') {
      return;
    }

    //local built_products_plist="${BUILT_PRODUCTS_DIR}/${INFOPLIST_PATH}"
    final String builtProductsPlist = '${environment['BUILT_PRODUCTS_DIR']}/${environment['INFOPLIST_PATH']}';

    //if [[ ! -f "${built_products_plist}" ]]; then
    if (existsFile(builtProductsPlist)) {
      //  # Very occasionally Xcode hasn't created an Info.plist when this runs.
      //  # The file will be present on re-run.
      //  echo "${INFOPLIST_PATH} does not exist. Skipping _dartobservatory._tcp NSBonjourServices insertion. Try re-building to enable \"flutter attach\"."
      //  return
      //fi
    }

    //# If there are already NSBonjourServices specified by the app (uncommon), insert the observatory service name to the existing list.
    //if plutil -extract NSBonjourServices xml1 -o - "${built_products_plist}"; then
    ProcessResult result = runSync(
      'plutil',
      <String>[
        '-extract',
        'NSBonjourServices',
        'xml1',
        '-o',
        '-',
        builtProductsPlist,
      ],
      allowFail: true,
    );
    if (result.exitCode == 0) {
      //  RunCommand plutil -insert NSBonjourServices.0 -string "_dartobservatory._tcp" "${built_products_plist}"
      runSync(
        'plutil',
        <String>[
          '-insert',
          'NSBonjourServices.0',
          '-string',
          '_dartobservatory._tcp',
          builtProductsPlist
        ],
      );
      //else
    } else {
      //  # Otherwise, add the NSBonjourServices key and observatory service name.
      //  RunCommand plutil -insert NSBonjourServices -json "[\"_dartobservatory._tcp\"]" "${built_products_plist}"
      runSync(
        'plutil',
        <String>[
          '-insert',
          'NSBonjourServices',
          '-json',
          '["_dartobservatory._tcp"]',
          builtProductsPlist,
        ],
      );
      //fi
    }

      //# Don't override the local network description the Flutter app developer specified (uncommon).
      //# This text will appear below the "Your app would like to find and connect to devices on your local network" permissions popup.
      //if ! plutil -extract NSLocalNetworkUsageDescription xml1 -o - "${built_products_plist}"; then
    result = runSync(
      'plutil',
      <String>[
        '-extract',
        'NSLocalNetworkUsageDescription',
        'xml1',
        '-o',
        '-',
        builtProductsPlist,
      ],
      allowFail: true,
    );
    if (result.exitCode != 0) {
      //  RunCommand plutil -insert NSLocalNetworkUsageDescription -string "Allow Flutter tools on your computer to connect and debug your application. This prompt will not appear on release builds." "${built_products_plist}"
      runSync(
        'plutil',
        <String>[
          '-insert',
          'NSLocalNetworkUsageDescription',
          '-string',
          'Allow Flutter tools on your computer to connect and debug your application. This prompt will not appear on release builds.',
          builtProductsPlist,
        ],
      );
      //fi
    }
  }

  void buildApp() {
    final bool verbose = environment['VERBOSE_SCRIPT_LOGGING'] != null && environment['VERBOSE_SCRIPT_LOGGING'] != '';
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
    final ProcessResult plistBuddyResult = runSync(
      '/usr/libexec/PlistBuddy',
      <String>['-c', '"Print :FLTAssetsPath"', '"$derivedDir/AppFrameworkInfo.plist"'],
      allowFail: true,
    );
    if (plistBuddyResult.exitCode == 0) {
      final String fltAssetsPath = (plistBuddyResult.stdout as String).trim();
      //  if [[ -n "$FLTAssetsPath" ]]; then
      if (fltAssetsPath.isNotEmpty) {
      //    assets_path="${FLTAssetsPath}"
        assetsPath = fltAssetsPath;
      //  fi
      }
      //fi
    }

    //# Use FLUTTER_BUILD_MODE if it's set, otherwise use the Xcode build configuration name
    //# This means that if someone wants to use an Xcode build config other than Debug/Profile/Release,
    //# they _must_ set FLUTTER_BUILD_MODE so we know what type of artifact to build.
    //local build_mode="$(ParseFlutterBuildMode)"
    final String buildMode = parseFlutterBuildMode();
    //local artifact_variant="unknown"
    String artifactVariant = 'unknown';
    //case "$build_mode" in
    switch (buildMode) {
    //  release ) artifact_variant="ios-release";;
      case 'release':
        artifactVariant = 'ios-release';
        break;
    //  profile ) artifact_variant="ios-profile";;
      case 'profile':
        artifactVariant = 'ios-profile';
        break;
    //  debug ) artifact_variant="ios";;
      case 'debug':
        artifactVariant = 'ios';
        break;
    //esac
    }

    //# Warn the user if not archiving (ACTION=install) in release mode.
    final String? action = environment['ACTION'];
    //if [[ "$ACTION" == "install" && "$build_mode" != "release" ]]; then
    if (action == 'install' && buildMode != 'release') {
      //  echo "warning: Flutter archive not built in Release mode. Ensure FLUTTER_BUILD_MODE \
      // is set to release or run \"flutter build ios --release\", then re-run Archive from Xcode."
      echo(
        'warning: Flutter archive not built in Release mode. Ensure '
        'FLUTTER_BUILD_MODE is set to release or run "flutter build ios '
        '--release", then re-run Archive from Xcode.',
      );
      //fi
    }
    //local framework_path="${FLUTTER_ROOT}/bin/cache/artifacts/engine/${artifact_variant}"
    final String frameworkPath = '${environmentEnsure('FLUTTER_ROOT')}/bin/cache/artifacts/engine/$artifactVariant';

    //local flutter_framework="${framework_path}/Flutter.xcframework"
    String flutterFramework = '$frameworkPath/Flutter.xcframework';

    final String? localEngine = environment['LOCAL_ENGINE'];
    //if [[ -n "$LOCAL_ENGINE" ]]; then
    if (localEngine != null) {
      //  if [[ $(echo "$LOCAL_ENGINE" | tr "[:upper:]" "[:lower:]") != *"$build_mode"* ]]; then
      if (!localEngine.toLowerCase().contains(buildMode)) {
        //    EchoError "========================================================================"
        echoError('========================================================================');
        //    EchoError "ERROR: Requested build with Flutter local engine at '${LOCAL_ENGINE}'"
        echoError("ERROR: Requested build with Flutter local engine at '$localEngine'");
        //    EchoError "This engine is not compatible with FLUTTER_BUILD_MODE: '${build_mode}'."
        echoError("This engine is not compatible with FLUTTER_BUILD_MODE: '$buildMode'.");
        //    EchoError "You can fix this by updating the LOCAL_ENGINE environment variable, or"
        echoError('You can fix this by updating the LOCAL_ENGINE environment variable, or');
        //    EchoError "by running:"
        echoError('by running:');
        //    EchoError "  flutter build ios --local-engine=ios_${build_mode}"
        echoError('  flutter build ios --local-engine=ios_$buildMode');
        //    EchoError "or"
        echoError('or');
        //    EchoError "  flutter build ios --local-engine=ios_${build_mode}_unopt"
        echoError('  flutter build ios --local-engine=ios_${buildMode}_unopt');
        //    EchoError "========================================================================"
        echoError('========================================================================');
        //    exit -1
        exitApp(-1);
        //  fi
      }
      //  flutter_framework="${FLUTTER_ENGINE}/out/${LOCAL_ENGINE}/Flutter.xcframework"
      flutterFramework = '${environmentEnsure('FLUTTER_ENGINE')}/out/$localEngine/Flutter.xcframework';
      //fi
    }
    //local bitcode_flag=""
    String bitcodeFlag = '';
    //if [[ "$ENABLE_BITCODE" == "YES" && "$ACTION" == "install" ]]; then
    if (environment['ENABLE_BITCODE'] == 'YES' && environment['ACTION'] == 'install') {
      //  bitcode_flag="true"
      bitcodeFlag = 'true';
      //fi
    }

    //# TODO(jmagman): use assemble copied engine in add-to-app.
    //if [[ -e "${project_path}/.ios" ]]; then
    if (existsDir('$projectPath/.ios')) {
      //  RunCommand rsync -av --delete --filter "- .DS_Store" "${flutter_framework}" "${derived_dir}/engine"
      runSync(
        'rsync',
        <String>[
          '-av',
          '--delete',
          '--filter',
          '"- .DS_Store"',
          flutterFramework,
          '$derivedDir/engine',
        ],
        verbose: verbose,
      );
      //fi
    }

    //RunCommand pushd "${project_path}" > /dev/null

    //# Construct the "flutter assemble" argument array. Arguments should be added
    //# as quoted string elements of the flutter_args array, otherwise an argument
    //# (like a path) with spaces in it might be interpreted as two separate
    //# arguments.

    //local flutter_args=("${FLUTTER_ROOT}/bin/flutter")
    final List<String> flutterArgs = <String>[
      //'${environmentEnsure('FLUTTER_ROOT')}/bin/flutter', // runSync takes this as first arg
    ];

    //if [[ -n "$VERBOSE_SCRIPT_LOGGING" ]]; then
    //  flutter_args+=('--verbose')
    //fi
    if (verbose) {
      flutterArgs.add('--verbose');
    }

    //if [[ -n "$FLUTTER_ENGINE" ]]; then
    //  flutter_args+=("--local-engine-src-path=${FLUTTER_ENGINE}")
    //fi
    if (environment['FLUTTER_ENGINE'] != null && environment['FLUTTER_ENGINE']!.isNotEmpty) {
      flutterArgs.add('--local-engine-src-path=${environment['FLUTTER_ENGINE']}');
    }

    //if [[ -n "$LOCAL_ENGINE" ]]; then
    //  flutter_args+=("--local-engine=${LOCAL_ENGINE}")
    //fi
    if (environment['LOCAL_ENGINE'] != null && environment['LOCAL_ENGINE']!.isNotEmpty) {
      flutterArgs.add('--local-engine=${environment['LOCAL_ENGINE']}');
    }

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
    flutterArgs.addAll(<String>[
      'assemble',
      '--no-version-check',
      '--output=${environment['BUILT_PRODUCTS_DIR'] ?? ''}/',
      '-dTargetPlatform=ios',
      '-dTargetFile=$targetPath',
      '-dBuildMode=$buildMode',
      '-dIosArchs=${environment['ARCHS'] ?? ''}',
      '-dSdkRoot=${environment['SDKROOT'] ?? ''}',
      '-dSplitDebugInfo=${environment['SPLIT_DEBUG_INFO'] ?? ''}',
      '-dTreeShakeIcons=${environment['TREE_SHAKE_ICONS'] ?? ''}',
      '-dTrackWidgetCreation=${environment['TRACK_WIDGET_CREATION'] ?? ''}',
      '-dDartObfuscation=${environment['DART_OBFUSCATION'] ?? ''}',
      '-dEnableBitcode=$bitcodeFlag',
      '--ExtraGenSnapshotOptions=${environment['EXTRA_GEN_SNAPSHOT_OPTIONS'] ?? ''}',
      '--DartDefines=${environment['DART_DEFINES'] ?? ''}',
      '--ExtraFrontEndOptions=${environment['EXTRA_FRONT_END_OPTIONS'] ?? ''}',
    ]);

    //if [[ -n "$PERFORMANCE_MEASUREMENT_FILE" ]]; then
    //  flutter_args+=("--performance-measurement-file=${PERFORMANCE_MEASUREMENT_FILE}")
    //fi
    if (environment['PERFORMANCE_MEASUREMENT_FILE'] != null && environment['PERFORMANCE_MEASUREMENT_FILE']!.isNotEmpty) {
      flutterArgs.add('--performance-measurement-file=${environment['PERFORMANCE_MEASUREMENT_FILE']}');
    }

    //if [[ -n "${EXPANDED_CODE_SIGN_IDENTITY:-}" && "${CODE_SIGNING_REQUIRED:-}" != "NO" ]]; then
    //  flutter_args+=("-dCodesignIdentity=${EXPANDED_CODE_SIGN_IDENTITY}")
    //fi
    final String? expandedCodeSignIdentity = environment['EXPANDED_CODE_SIGN_IDENTITY'];
    if (expandedCodeSignIdentity != null && expandedCodeSignIdentity.isNotEmpty && environment['CODE_SIGNING_REQUIRED'] != 'NO') {
      flutterArgs.add('--dCodesignIdentity=$expandedCodeSignIdentity');
    }


    //if [[ -n "$BUNDLE_SKSL_PATH" ]]; then
    //  flutter_args+=("-dBundleSkSLPath=${BUNDLE_SKSL_PATH}")
    //fi
    if (environment['BUNDLE_SKSL_PATH'] != null && environment['BUNDLE_SKSL_PATH']!.isNotEmpty) {
      flutterArgs.add('-dBundleSkSLPath=${environment['BUNDLE_SKSL_PATH']}');
    }

    //if [[ -n "$CODE_SIZE_DIRECTORY" ]]; then
    //  flutter_args+=("-dCodeSizeDirectory=${CODE_SIZE_DIRECTORY}")
    //fi
    if (environment['CODE_SIZE_DIRECTORY'] != null && environment['CODE_SIZE_DIRECTORY']!.isNotEmpty) {
      flutterArgs.add('-dCodeSizeDirectory=${environment['CODE_SIZE_DIRECTORY']}');
    }

    //flutter_args+=("${build_mode}_ios_bundle_flutter_assets")
    flutterArgs.add('${buildMode}_ios_bundle_flutter_assets');

    //RunCommand "${flutter_args[@]}"
    final ProcessResult result = runSync(
      '${environmentEnsure('FLUTTER_ROOT')}/bin/flutter',
      flutterArgs,
      verbose: verbose,
      allowFail: true,
      workingDirectory: projectPath, // equivalent of RunCommand pushd "${project_path}"
    );

    //if [[ $? -ne 0 ]]; then
    //  EchoError "Failed to package ${project_path}."
    //  exit -1
    //fi
    if (result.exitCode != 0) {
      echoError('Failed to package $projectPath.');
      exitApp(-1);
    }

    //StreamOutput "done"
    //StreamOutput " └─Compiling, linking and signing..."
    streamOutput('done');
    streamOutput(' └─Compiling, linking and signing...');

    //RunCommand popd > /dev/null

    //echo "Project ${project_path} built and packaged successfully."
    echo('Project $projectPath built and packaged successfully.');
    //return 0
  }
}
