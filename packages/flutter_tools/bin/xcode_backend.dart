// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

void main(List<String> arguments) {
  File? scriptOutputStreamFile;
  final String? scriptOutputStreamFileEnv = Platform.environment['SCRIPT_OUTPUT_STREAM_FILE'];
  if (scriptOutputStreamFileEnv != null && scriptOutputStreamFileEnv.isNotEmpty) {
    scriptOutputStreamFile = File(scriptOutputStreamFileEnv);
  }
  Context(
    arguments: arguments,
    environment: Platform.environment,
    scriptOutputStreamFile: scriptOutputStreamFile,
  ).run();
}

/// Container for script arguments and environment variables.
///
/// All interactions with the platform are broken into individual methods that
/// can be overridden in tests.
class Context {
  Context({required this.arguments, required this.environment, File? scriptOutputStreamFile}) {
    if (scriptOutputStreamFile != null) {
      scriptOutputStream = scriptOutputStreamFile.openSync(mode: FileMode.write);
    }
  }

  final Map<String, String> environment;
  final List<String> arguments;
  RandomAccessFile? scriptOutputStream;

  static const incompatibleErrorMessage =
      'Your Xcode project is incompatible with this version of Flutter. '
      'Run "rm -rf ios/Runner.xcodeproj" and "flutter create ." to regenerate.\n';

  void run() {
    if (arguments.isEmpty) {
      // Named entry points were introduced in Flutter v0.0.7.
      echoXcodeError(incompatibleErrorMessage);
      exit(-1);
    }

    final String subCommand = validateCommand(arguments[0]);
    final String? platformName = arguments.length < 2 ? null : arguments[1];
    final TargetPlatform platform = parsePlatform(platformName);
    switch (subCommand) {
      case 'build':
        buildApp(platform);
      case 'prepare':
        prepare(platform);
      case 'thin':
        // No-op, thinning is handled during the bundle asset assemble build target.
        break;
      case 'embed':
      case 'embed_and_thin':
        // Thinning is handled during the bundle asset assemble build target, so just embed.
        embedFlutterFrameworks(platform);
      case 'test_vm_service_bonjour_service':
        // Exposed for integration testing only.
        addVmServiceBonjourService();
    }
  }

  /// Validates the command argument matches one of the possible commands.
  /// Returns null if not.
  String validateCommand(String command) {
    switch (command) {
      case 'build':
      case 'prepare':
      case 'thin':
      case 'embed':
      case 'embed_and_thin':
      case 'test_vm_service_bonjour_service':
        return command;
      default:
        echoXcodeError(incompatibleErrorMessage);
        exit(-1);
    }
  }

  /// Converts the [platformName] argument to a [TargetPlatform]. If there is
  /// not a match, prints a warning and defaults to [TargetPlatform.ios].
  TargetPlatform parsePlatform(String? platformName) {
    switch (platformName) {
      case 'macos':
        return TargetPlatform.macos;
      case 'ios':
        return TargetPlatform.ios;
      default:
        echoXcodeWarning('Unrecognized platform: $platformName. Defaulting to iOS.');
        return TargetPlatform.ios;
    }
  }

  bool existsFile(String path) {
    final file = File(path);
    return file.existsSync();
  }

  Directory directoryFromPath(String path) => Directory(path);

  File fileFromPath(String path) => File(path);

  /// Run given command ([bin]) in a synchronous subprocess.
  ///
  /// If [allowFail] is true, an exception will not be thrown even if the process returns a
  /// non-zero exit code. Also, `error:` will not be prefixed to the output to prevent Xcode
  /// complication failures.
  ///
  /// If [skipErrorLog] is true, `stderr` from the process will not be output unless in [verbose]
  /// mode. If in [verbose], pipes `stderr` to `stdout`.
  ///
  /// Will throw [Exception] if the exit code is not 0.
  ProcessResult runSync(
    String bin,
    List<String> args, {
    bool verbose = false,
    bool allowFail = false,
    bool skipErrorLog = false,
    String? workingDirectory,
  }) {
    if (verbose) {
      print('♦ $bin ${args.join(' ')}');
    }
    final ProcessResult result = runSyncProcess(bin, args, workingDirectory: workingDirectory);
    if (verbose) {
      print((result.stdout as String).trim());
    }
    final String resultStderr = result.stderr.toString().trim();
    if (resultStderr.isNotEmpty) {
      final errorOutput = StringBuffer();
      if (!allowFail && result.exitCode != 0) {
        // "error:" prefix makes this show up as an Xcode compilation error.
        errorOutput.write('error: ');
      }
      errorOutput.write(resultStderr);
      if (skipErrorLog) {
        // Even if skipErrorLog, we still want to write to stdout if verbose.
        if (verbose) {
          echo(errorOutput.toString());
        }
      } else {
        echoError(errorOutput.toString());
      }
      // Stream stderr to the Flutter build process.
      // When in verbose mode, `echoError` above will show the logs. So only
      // stream if not in verbose mode to avoid duplicate logs.
      // Also, only stream if exitCode is 0 since errors are handled separately
      // by the tool on failure.
      // Also check for `skipErrorLog`, because some errors should not be printed
      // out. For example, on macOS 26, plutil reports NSBonjourServices key not
      // found as an error. However, logging it in non-verbose mode would be
      // confusing, since not having the key is one of the expected states.
      if (!verbose && exitCode == 0 && !skipErrorLog) {
        streamOutput(errorOutput.toString());
      }
    }
    if (!allowFail && result.exitCode != 0) {
      throw Exception('Command "$bin ${args.join(' ')}" exited with code ${result.exitCode}');
    }
    return result;
  }

  // TODO(hellohuanlin): Instead of using inheritance to stub the function in
  // the subclass, we should favor composition by injecting the dependencies.
  // See: https://github.com/flutter/flutter/issues/173133
  ProcessResult runSyncProcess(String bin, List<String> args, {String? workingDirectory}) {
    return Process.runSync(bin, args, workingDirectory: workingDirectory);
  }

  /// Log message to stderr.
  void echoError(String message) {
    stderr.writeln(message);
  }

  /// Log message to stderr.
  void echoXcodeError(String message) {
    stderr.writeln('error: $message');
  }

  /// Log message appended with `warning:` to stderr.
  /// This will display with a yellow warning icon in Xcode.
  void echoXcodeWarning(String message) {
    stderr.writeln('warning: $message');
  }

  /// Log message to stdout.
  void echo(String message) {
    stdout.write(message);
  }

  /// Exit the application with the given exit code.
  ///
  /// Exists to allow overriding in tests.
  Never exitApp(int code) {
    exit(code);
  }

  /// Return value from environment if it exists, else throw [Exception].
  String environmentEnsure(String key) {
    final String? value = environment[key];
    if (value == null) {
      throw Exception('Expected the environment variable "$key" to exist, but it was not found');
    }
    return value;
  }

  // When provided with a pipe by the host Flutter build process, output to the
  // pipe goes to stdout of the Flutter build process directly.
  void streamOutput(String output) {
    scriptOutputStream?.writeStringSync('$output\n');
  }

  /// Parses and normalizes the build mode (debug, profile, release).
  ///
  /// Uses `FLUTTER_BUILD_MODE` (uncommon) if set, otherwise uses `CONFIGURATION`.
  /// The `CONFIGURATION` may not match exactly since it can be named by the developer.
  /// If the `FLUTTER_BUILD_MODE` and `CONFIGURATION` do not contain either
  /// debug, profile, or release, prints an error and exits the build.
  String parseFlutterBuildMode() {
    // Use FLUTTER_BUILD_MODE if it's set, otherwise use the Xcode build configuration name
    // This means that if someone wants to use an Xcode build config other than Debug/Profile/Release,
    // they _must_ set FLUTTER_BUILD_MODE so we know what type of artifact to build.
    final String? buildMode = (environment['FLUTTER_BUILD_MODE'] ?? environment['CONFIGURATION'])
        ?.toLowerCase();

    if (buildMode != null) {
      if (buildMode.contains('release')) {
        return 'release';
      }
      if (buildMode.contains('profile')) {
        return 'profile';
      }
      if (buildMode.contains('debug')) {
        return 'debug';
      }
    }
    echoError('========================================================================');
    echoError('ERROR: Unknown FLUTTER_BUILD_MODE: $buildMode.');
    echoError("Valid values are 'Debug', 'Profile', or 'Release' (case insensitive).");
    echoError('This is controlled by the FLUTTER_BUILD_MODE environment variable.');
    echoError('If that is not set, the CONFIGURATION environment variable is used.');
    echoError('');
    echoError('You can fix this by either adding an appropriately named build');
    echoError('configuration, or adding an appropriate value for FLUTTER_BUILD_MODE to the');
    echoError(
      '.xcconfig file for the current build configuration (${environment['CONFIGURATION']}).',
    );
    echoError('========================================================================');
    exitApp(-1);
  }

  /// Copies all files from [source] to [destination].
  ///
  /// Does not copy `.DS_Store`.
  ///
  /// Deletes extraneous files from [destination].
  void runRsync(String source, String destination, {List<String> extraArgs = const <String>[]}) {
    runSync('rsync', <String>[
      '-8', // Avoid mangling filenames with encodings that do not match the current locale.
      '-av',
      '--delete',
      '--filter',
      '- .DS_Store',
      ...extraArgs,
      source,
      destination,
    ]);
  }

  /// Embeds the App.framework, Flutter/FlutterMacOS.framework, and any native
  /// asset frameworks into the app.
  ///
  /// On macOS, also codesigns the framework binaries. Codesigning occurs here rather
  /// than during the Run Script `build` phase because the `EXPANDED_CODE_SIGN_IDENTITY`
  /// is not passed in the build settings during the `build` phase for macOS.
  ///
  /// On iOS, also injects local network permissions into the app's Info.plist.
  void embedFlutterFrameworks(TargetPlatform platform) {
    // Embed App.framework from Flutter into the app (after creating the Frameworks directory
    // if it doesn't already exist).
    final xcodeFrameworksDir =
        '${environment['TARGET_BUILD_DIR']}/${environment['FRAMEWORKS_FOLDER_PATH']}';
    runSync('mkdir', <String>['-p', '--', xcodeFrameworksDir]);
    runRsync('${environment['BUILT_PRODUCTS_DIR']}/App.framework', xcodeFrameworksDir);

    final String? expandedCodeSignIdentity = environment['EXPANDED_CODE_SIGN_IDENTITY'];

    final bool codesign =
        platform == TargetPlatform.macos &&
        expandedCodeSignIdentity != null &&
        expandedCodeSignIdentity.isNotEmpty &&
        environment['CODE_SIGNING_REQUIRED'] != 'NO';

    // Embed the actual Flutter.framework that the Flutter app expects to run against,
    // which could be a local build or an arch/type specific build.
    switch (platform) {
      case TargetPlatform.ios:
        runRsync('${environment['BUILT_PRODUCTS_DIR']}/Flutter.framework', '$xcodeFrameworksDir/');
      case TargetPlatform.macos:
        runRsync(
          extraArgs: <String>['--filter', '- Headers', '--filter', '- Modules'],
          '${environment['BUILT_PRODUCTS_DIR']}/FlutterMacOS.framework',
          '$xcodeFrameworksDir/',
        );

        if (codesign) {
          _codesignFramework(expandedCodeSignIdentity, '$xcodeFrameworksDir/App.framework/App');
          _codesignFramework(
            expandedCodeSignIdentity,
            '$xcodeFrameworksDir/FlutterMacOS.framework/FlutterMacOS',
          );
        }
    }

    _embedNativeAssets(
      platform,
      xcodeFrameworksDir: xcodeFrameworksDir,
      codesign: codesign,
      expandedCodeSignIdentity: expandedCodeSignIdentity,
    );

    if (platform == TargetPlatform.ios) {
      addVmServiceBonjourService();
    }
  }

  void _embedNativeAssets(
    TargetPlatform platform, {
    required String xcodeFrameworksDir,
    required bool codesign,
    String? expandedCodeSignIdentity,
  }) {
    // Copy native assets referenced in the native_assets.json file for the
    // current build.
    final String sourceRoot = environment['SOURCE_ROOT'] ?? '';
    var projectPath = '$sourceRoot/..';
    if (environment['FLUTTER_APPLICATION_PATH'] != null) {
      projectPath = environment['FLUTTER_APPLICATION_PATH']!;
    }
    final String flutterBuildDir = environment['FLUTTER_BUILD_DIR']!;
    final nativeAssetsPath = '$projectPath/$flutterBuildDir/native_assets/${platform.name}/';
    final bool verbose = (environment['VERBOSE_SCRIPT_LOGGING'] ?? '').isNotEmpty;

    final Set<String> referencedFrameworks = {};
    final appResourcesDir = platform == TargetPlatform.macos ? 'Resources/' : '';
    final File nativeAssetsJson = fileFromPath(
      '$xcodeFrameworksDir/App.framework/${appResourcesDir}flutter_assets/NativeAssetsManifest.json',
    );
    if (!nativeAssetsJson.existsSync()) {
      if (verbose) {
        print("♦ No native assets to bundle. ${nativeAssetsJson.path} doesn't exist.");
      }
      return;
    }
    // NativeAssetsManifest.json looks like this: {
    //   "format-version":[1,0,0],
    //   "native-assets":{
    //     "ios_arm64":{
    //       "package:sqlite3/src/ffi/libsqlite3.g.dart":[
    //         "absolute",
    //         "sqlite3arm64ios.framework/sqlite3arm64ios"
    //       ]
    //     }
    //   }
    // }
    //
    // Note that this format is also parsed and expected in
    // engine/src/flutter/assets/native_assets.cc
    try {
      final nativeAssetsSpec = json.decode(nativeAssetsJson.readAsStringSync()) as Map;
      for (final Object? perPlatform
          in (nativeAssetsSpec['native-assets'] as Map<String, Object?>).values) {
        for (final Object? asset in (perPlatform! as Map<String, Object?>).values) {
          if (asset case ['absolute', final String frameworkPath]) {
            // frameworkPath is usually something like sqlite3arm64ios.framework/sqlite3arm64ios
            final [String directory, String name] = frameworkPath.split('/');
            if (directory != '$name.framework') {
              throw Exception(
                'Unexpected framework path: $frameworkPath. Should be $name.framework/$name',
              );
            }

            referencedFrameworks.add(name);
          }
        }
      }
    } on Object catch (e, stackTrace) {
      echo(e.toString());
      echo(stackTrace.toString());
      echoXcodeError('Failed to embed native assets: $e');
      exitApp(-1);
    }

    if (verbose) {
      print('♦ Copying native assets ${referencedFrameworks.join(', ')} from $nativeAssetsPath.');
    }

    for (final framework in referencedFrameworks) {
      final Directory frameworkDirectory = directoryFromPath(
        '$nativeAssetsPath$framework.framework',
      );
      if (!frameworkDirectory.existsSync()) {
        throw Exception(
          'The native assets specification at ${nativeAssetsJson.path} references $framework, '
          'which was not found in $nativeAssetsPath.',
        );
      }

      runRsync(
        extraArgs: <String>['--filter', '- native_assets.yaml', '--filter', '- native_assets.json'],
        frameworkDirectory.path,
        xcodeFrameworksDir,
      );
      if (codesign && expandedCodeSignIdentity != null) {
        _codesignFramework(
          expandedCodeSignIdentity,
          '$xcodeFrameworksDir/$framework.framework/$framework',
        );
      }
    }
  }

  void _codesignFramework(String expandedCodeSignIdentity, String frameworkPath) {
    runSync('codesign', <String>[
      '--force',
      '--verbose',
      '--sign',
      expandedCodeSignIdentity,
      '--',
      frameworkPath,
    ]);
  }

  /// Add the vmService publisher Bonjour service to the produced app bundle Info.plist.
  void addVmServiceBonjourService() {
    // Skip adding Bonjour service settings when DISABLE_PORT_PUBLICATION is YES.
    // These settings are not needed if port publication is disabled.
    if (environment['DISABLE_PORT_PUBLICATION'] == 'YES') {
      return;
    }

    final String buildMode = parseFlutterBuildMode();

    // Debug and profile only.
    if (buildMode == 'release') {
      return;
    }

    final builtProductsPlist =
        '${environment['BUILT_PRODUCTS_DIR'] ?? ''}/${environment['INFOPLIST_PATH'] ?? ''}';

    if (!existsFile(builtProductsPlist)) {
      // Very occasionally Xcode hasn't created an Info.plist when this runs.
      // The file will be present on re-run.
      echo(
        '${environment['INFOPLIST_PATH'] ?? ''} does not exist. Skipping '
        '_dartVmService._tcp NSBonjourServices insertion. Try re-building to '
        'enable "flutter attach".',
      );
      return;
    }

    final bool verbose = (environment['VERBOSE_SCRIPT_LOGGING'] ?? '').isNotEmpty;

    // If there are already NSBonjourServices specified by the app (uncommon),
    // insert the vmService service name to the existing list.
    ProcessResult result = runSync(
      'plutil',
      <String>['-extract', 'NSBonjourServices', 'xml1', '-o', '-', builtProductsPlist],
      verbose: verbose,
      allowFail: true,
      skipErrorLog: true,
    );
    if (result.exitCode == 0) {
      runSync('plutil', <String>[
        '-insert',
        'NSBonjourServices.0',
        '-string',
        '_dartVmService._tcp',
        builtProductsPlist,
      ]);
    } else {
      // Otherwise, add the NSBonjourServices key and vmService service name.
      runSync('plutil', <String>[
        '-insert',
        'NSBonjourServices',
        '-json',
        '["_dartVmService._tcp"]',
        builtProductsPlist,
      ]);
      //fi
    }

    // Don't override the local network description the Flutter app developer
    // specified (uncommon). This text will appear below the "Your app would
    // like to find and connect to devices on your local network" permissions
    // popup.
    result = runSync(
      'plutil',
      <String>['-extract', 'NSLocalNetworkUsageDescription', 'xml1', '-o', '-', builtProductsPlist],
      verbose: verbose,
      allowFail: true,
      skipErrorLog: true,
    );
    if (result.exitCode != 0) {
      runSync('plutil', <String>[
        '-insert',
        'NSLocalNetworkUsageDescription',
        '-string',
        'Allow Flutter tools on your computer to connect and debug your application. This prompt will not appear on release builds.',
        builtProductsPlist,
      ]);
    }
  }

  /// Calls `flutter assemble [buildMode]_unpack_[platform]` (e.g. `debug_unpack_ios`, `debug_unpack_macos`)
  void prepare(TargetPlatform platform) {
    // The "prepare" command runs in a pre-action script, which also runs when
    // using the Xcode/xcodebuild clean command. Skip if cleaning.
    if (environment['ACTION'] == 'clean') {
      return;
    }
    final bool verbose = (environment['VERBOSE_SCRIPT_LOGGING'] ?? '').isNotEmpty;
    final String sourceRoot = environment['SOURCE_ROOT'] ?? '';
    final String projectPath = environment['FLUTTER_APPLICATION_PATH'] ?? '$sourceRoot/..';

    final String buildMode = parseFlutterBuildMode();

    final List<String> flutterArgs = _generateFlutterArgsForAssemble(
      command: 'prepare',
      buildMode: buildMode,
      sourceRoot: sourceRoot,
      platform: platform,
      verbose: verbose,
    );

    // The "prepare" command only targets the UnpackIOS/UnpackMacOS target, which copies the
    // Flutter framework to the BUILT_PRODUCTS_DIR.
    flutterArgs.add('${buildMode}_unpack_${platform.name}');

    final ProcessResult result = runSync(
      '${environmentEnsure('FLUTTER_ROOT')}/bin/flutter',
      flutterArgs,
      verbose: verbose,
      allowFail: true,
      workingDirectory: projectPath, // equivalent of RunCommand pushd "${project_path}"
    );

    if (result.exitCode != 0) {
      echoError('Failed to copy Flutter framework.');
      exitApp(-1);
    }
  }

  /// Calls `flutter assemble [buildMode]_[platform]_bundle_flutter_assets`
  /// (e.g. `debug_ios_bundle_flutter_assets`, `debug_macos_bundle_flutter_assets`)
  void buildApp(TargetPlatform platform) {
    final bool verbose = (environment['VERBOSE_SCRIPT_LOGGING'] ?? '').isNotEmpty;
    final String sourceRoot = environment['SOURCE_ROOT'] ?? '';
    final String projectPath = environment['FLUTTER_APPLICATION_PATH'] ?? '$sourceRoot/..';

    final String buildMode = parseFlutterBuildMode();

    final List<String> flutterArgs = _generateFlutterArgsForAssemble(
      command: 'build',
      buildMode: buildMode,
      sourceRoot: sourceRoot,
      platform: platform,
      verbose: verbose,
    );

    flutterArgs.add('${buildMode}_${platform.name}_bundle_flutter_assets');
    final ProcessResult result = runSync(
      '${environmentEnsure('FLUTTER_ROOT')}/bin/flutter',
      flutterArgs,
      verbose: verbose,
      allowFail: true,
      workingDirectory: projectPath, // equivalent of RunCommand pushd "${project_path}"
    );

    if (result.exitCode != 0) {
      echoError('Failed to package $projectPath.');
      exitApp(-1);
    }

    streamOutput('done');
    streamOutput(' └─Compiling, linking and signing...');

    echo('Project $projectPath built and packaged successfully.');
  }

  List<String> _generateFlutterArgsForAssemble({
    required String command,
    required String buildMode,
    required String sourceRoot,
    required TargetPlatform platform,
    required bool verbose,
  }) {
    var targetPath = 'lib/main.dart';
    if (environment['FLUTTER_TARGET'] != null) {
      targetPath = environment['FLUTTER_TARGET']!;
    }

    // Warn the user if not archiving (ACTION=install) in release mode.
    final String? action = environment['ACTION'];
    if (action == 'install' && buildMode != 'release') {
      echoXcodeWarning(
        'Flutter archive not built in Release mode. Ensure '
        'FLUTTER_BUILD_MODE is set to release or run "flutter build ios '
        '--release", then re-run Archive from Xcode.',
      );
    }

    final flutterArgs = <String>[];

    if (verbose) {
      flutterArgs.add('--verbose');
    }

    if (environment['FLUTTER_ENGINE'] != null && environment['FLUTTER_ENGINE']!.isNotEmpty) {
      flutterArgs.add('--local-engine-src-path=${environment['FLUTTER_ENGINE']}');
    }

    if (environment['LOCAL_ENGINE'] != null && environment['LOCAL_ENGINE']!.isNotEmpty) {
      flutterArgs.add('--local-engine=${environment['LOCAL_ENGINE']}');
    }

    if (environment['LOCAL_ENGINE_HOST'] != null && environment['LOCAL_ENGINE_HOST']!.isNotEmpty) {
      flutterArgs.add('--local-engine-host=${environment['LOCAL_ENGINE_HOST']}');
    }

    // The "prepare" command runs in a pre-action script, which doesn't always
    // filter the "ARCHS" build setting. Attempt to filter the architecture
    // to improve caching. If this filter is incorrect, it will later be
    // corrected by the "build" command.
    String archs = environment['ARCHS'] ?? '';
    if (command == 'prepare' && archs.contains(' ')) {
      // If "ONLY_ACTIVE_ARCH" is "YES", the product includes only code for the
      // native architecture ("NATIVE_ARCH").
      final String? nativeArch = environment['NATIVE_ARCH'];
      if (environment['ONLY_ACTIVE_ARCH'] == 'YES' && nativeArch != null) {
        if (nativeArch.contains('arm64') && archs.contains('arm64')) {
          archs = 'arm64';
        } else if (nativeArch.contains('x86_64') && archs.contains('x86_64')) {
          archs = 'x86_64';
        }
      }
    }

    final String targetPlatform;
    final String platformArches;
    switch (platform) {
      case TargetPlatform.ios:
        targetPlatform = '-dTargetPlatform=ios';
        platformArches = '-dIosArchs=$archs';
      case TargetPlatform.macos:
        targetPlatform = '-dTargetPlatform=darwin';
        platformArches = '-dDarwinArchs=$archs';
    }

    flutterArgs.addAll(<String>[
      'assemble',
      '--no-version-check',
      '--output=${environment['BUILT_PRODUCTS_DIR'] ?? ''}/',
      targetPlatform,
      '-dTargetFile=$targetPath',
      '-dBuildMode=$buildMode',
      // FLAVOR is set by the Flutter CLI in the Flutter/Generated.xcconfig file
      // when the --flavor flag is used, so it may not always be present.
      if (environment['FLAVOR'] != null) '-dFlavor=${environment['FLAVOR']}',
      '-dConfiguration=${environment['CONFIGURATION']}',
      platformArches,
      '-dSdkRoot=${environment['SDKROOT'] ?? ''}',
      '-dSplitDebugInfo=${environment['SPLIT_DEBUG_INFO'] ?? ''}',
      '-dTreeShakeIcons=${environment['TREE_SHAKE_ICONS'] ?? ''}',
      '-dTrackWidgetCreation=${environment['TRACK_WIDGET_CREATION'] ?? ''}',
      '-dDartObfuscation=${environment['DART_OBFUSCATION'] ?? ''}',
      '-dAction=${environment['ACTION'] ?? ''}',
      '-dFrontendServerStarterPath=${environment['FRONTEND_SERVER_STARTER_PATH'] ?? ''}',
      '--ExtraGenSnapshotOptions=${environment['EXTRA_GEN_SNAPSHOT_OPTIONS'] ?? ''}',
      '--DartDefines=${environment['DART_DEFINES'] ?? ''}',
      '--ExtraFrontEndOptions=${environment['EXTRA_FRONT_END_OPTIONS'] ?? ''}',
      '-dSrcRoot=${environment['SRCROOT'] ?? ''}',
    ]);

    if (platform == TargetPlatform.ios) {
      flutterArgs.add('-dTargetDeviceOSVersion=${environment['TARGET_DEVICE_OS_VERSION'] ?? ''}');
      final String? expandedCodeSignIdentity = environment['EXPANDED_CODE_SIGN_IDENTITY'];
      if (expandedCodeSignIdentity != null &&
          expandedCodeSignIdentity.isNotEmpty &&
          environment['CODE_SIGNING_REQUIRED'] != 'NO') {
        flutterArgs.add('-dCodesignIdentity=$expandedCodeSignIdentity');
      }
    }
    if (platform == TargetPlatform.macos && command == 'build') {
      final ephemeralDirectory = '$sourceRoot/Flutter/ephemeral';
      final buildInputsPath = '$ephemeralDirectory/FlutterInputs.xcfilelist';
      final buildOutputsPath = '$ephemeralDirectory/FlutterOutputs.xcfilelist';
      flutterArgs.addAll(<String>[
        '--build-inputs=$buildInputsPath',
        '--build-outputs=$buildOutputsPath',
      ]);
    }

    if (command == 'prepare') {
      // Use the PreBuildAction define flag to force the tool to use a different
      // filecache file for the "prepare" command. This will make the environment
      // buildPrefix for the "prepare" command unique from the "build" command.
      // This will improve caching since the "build" command has more target dependencies.
      flutterArgs.add('-dPreBuildAction=PrepareFramework');
    }

    if (environment['PERFORMANCE_MEASUREMENT_FILE'] != null &&
        environment['PERFORMANCE_MEASUREMENT_FILE']!.isNotEmpty) {
      flutterArgs.add(
        '--performance-measurement-file=${environment['PERFORMANCE_MEASUREMENT_FILE']}',
      );
    }

    if (environment['CODE_SIZE_DIRECTORY'] != null &&
        environment['CODE_SIZE_DIRECTORY']!.isNotEmpty) {
      flutterArgs.add('-dCodeSizeDirectory=${environment['CODE_SIZE_DIRECTORY']}');
    }

    return flutterArgs;
  }
}

enum TargetPlatform { ios, macos }
