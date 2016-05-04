// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as path;

import '../android/android_sdk.dart';
import '../artifacts.dart';
import '../base/context.dart';
import '../base/logger.dart';
import '../base/process.dart';
import '../build_configuration.dart';
import '../globals.dart';
import '../package_map.dart';
import '../toolchain.dart';
import 'version.dart';

const String kFlutterRootEnvironmentVariableName = 'FLUTTER_ROOT'; // should point to //flutter/ (root of flutter/flutter repo)
const String kFlutterEngineEnvironmentVariableName = 'FLUTTER_ENGINE'; // should point to //engine/src/ (root of flutter/engine repo)
const String kSnapshotFileName = 'flutter_tools.snapshot'; // in //flutter/bin/cache/
const String kFlutterToolsScriptFileName = 'flutter_tools.dart'; // in //flutter/packages/flutter_tools/bin/
const String kFlutterEnginePackageName = 'sky_engine';

class FlutterCommandRunner extends CommandRunner {
  FlutterCommandRunner({ bool verboseHelp: false }) : super(
    'flutter',
    'Manage your Flutter app development.'
  ) {
    argParser.addFlag('verbose',
        abbr: 'v',
        negatable: false,
        help: 'Noisy logging, including all shell commands executed.');
    argParser.addOption('device-id',
        abbr: 'd',
        help: 'Target device id.');
    argParser.addFlag('version',
        negatable: false,
        help: 'Reports the version of this tool.');
    argParser.addFlag('color',
        negatable: true,
        hide: !verboseHelp,
        help: 'Whether to use terminal colors.');

    String packagesHelp;
    if (FileSystemEntity.isFileSync('.packages'))
      packagesHelp = '\n(defaults to ".packages")';
    else
      packagesHelp = '\n(required, since the current directory does not contain a ".packages" file)';
    argParser.addOption('packages',
        hide: !verboseHelp,
        help: 'Path to your ".packages" file.$packagesHelp');
    argParser.addOption('flutter-root',
        help: 'The root directory of the Flutter repository (uses \$$kFlutterRootEnvironmentVariableName if set).',
              defaultsTo: _defaultFlutterRoot);

    if (verboseHelp)
      argParser.addSeparator('Local build selection options (not normally required):');

    argParser.addFlag('engine-debug',
        negatable: false,
        hide: !verboseHelp,
        help:
            'Set this if you are building Flutter locally and want to use the debug build products.\n'
            'Defaults to true if --engine-src-path is specified and --engine-release is not, otherwise false.');
    argParser.addFlag('engine-release',
        negatable: false,
        hide: !verboseHelp,
        help:
            'Set this if you are building Flutter locally and want to use the release build products.\n'
            'The --engine-release option is not compatible with the listen command on iOS devices and simulators.');
    argParser.addOption('engine-src-path',
        hide: !verboseHelp,
        help:
            'Path to your engine src directory, if you are building Flutter locally.\n'
            'Defaults to \$$kFlutterEngineEnvironmentVariableName if set, otherwise defaults to the path given in your pubspec.yaml\n'
            'dependency_overrides for $kFlutterEnginePackageName, if any, or, failing that, tries to guess at the location\n'
            'based on the value of the --flutter-root option.');

    argParser.addOption('host-debug-build-path',
        hide: !verboseHelp,
        help:
            'Path to your host Debug out directory (i.e. the one that runs on your workstation, not a device),\n'
            'if you are building Flutter locally.\n'
            'This path is relative to --engine-src-path. Not normally required.',
        defaultsTo: 'out/Debug/');
    argParser.addOption('host-release-build-path',
        hide: !verboseHelp,
        help:
            'Path to your host Release out directory (i.e. the one that runs on your workstation, not a device),\n'
            'if you are building Flutter locally.\n'
            'This path is relative to --engine-src-path. Not normally required.',
        defaultsTo: 'out/Release/');

    argParser.addOption('android-debug-build-path',
        hide: !verboseHelp,
        help:
            'Path to your Android Debug out directory, if you are building Flutter locally.\n'
            'This path is relative to --engine-src-path. Not normally required.',
        defaultsTo: 'out/android_Debug/');
    argParser.addOption('android-release-build-path',
        hide: !verboseHelp,
        help:
            'Path to your Android Release out directory, if you are building Flutter locally.\n'
            'This path is relative to --engine-src-path. Not normally required.',
        defaultsTo: 'out/android_Release/');
    argParser.addOption('ios-debug-build-path',
        hide: !verboseHelp,
        help:
            'Path to your iOS Debug out directory, if you are building Flutter locally.\n'
            'This path is relative to --engine-src-path. Not normally required.',
        defaultsTo: 'out/ios_Debug/');
    argParser.addOption('ios-release-build-path',
        hide: !verboseHelp,
        help:
            'Path to your iOS Release out directory, if you are building Flutter locally.\n'
            'This path is relative to --engine-src-path. Not normally required.',
        defaultsTo: 'out/ios_Release/');
    argParser.addOption('ios-sim-debug-build-path',
        hide: !verboseHelp,
        help:
            'Path to your iOS Simulator Debug out directory, if you are building Flutter locally.\n'
            'This path is relative to --engine-src-path. Not normally required.',
        defaultsTo: 'out/ios_sim_Debug/');
    argParser.addOption('ios-sim-release-build-path',
        hide: !verboseHelp,
        help:
            'Path to your iOS Simulator Release out directory, if you are building Flutter locally.\n'
            'This path is relative to --engine-src-path. Not normally required.',
        defaultsTo: 'out/ios_sim_Release/');
  }

  @override
  String get usageFooter {
    return 'Run "flutter -h -v" for verbose help output, including less commonly used options.';
  }

  List<BuildConfiguration> get buildConfigurations {
    if (_buildConfigurations == null)
      _buildConfigurations = _createBuildConfigurations(_globalResults);
    return _buildConfigurations;
  }
  List<BuildConfiguration> _buildConfigurations;

  String get enginePath {
    assert(ArtifactStore.flutterRoot != null);
    _enginePath ??= _findEnginePath(_globalResults);
    return _enginePath;
  }
  String _enginePath;

  ArgResults _globalResults;

  static String get _defaultFlutterRoot {
    if (Platform.environment.containsKey(kFlutterRootEnvironmentVariableName))
      return Platform.environment[kFlutterRootEnvironmentVariableName];
    try {
      if (Platform.script.scheme == 'data')
        return '../..'; // we're running as a test
      String script = Platform.script.toFilePath();
      if (path.basename(script) == kSnapshotFileName)
        return path.dirname(path.dirname(path.dirname(script)));
      if (path.basename(script) == kFlutterToolsScriptFileName)
        return path.dirname(path.dirname(path.dirname(path.dirname(script))));

      // If run from a bare script within the repo.
      if (script.contains('flutter/packages/'))
        return script.substring(0, script.indexOf('flutter/packages/') + 8);
      if (script.contains('flutter/examples/'))
        return script.substring(0, script.indexOf('flutter/examples/') + 8);
    } catch (error) {
      // we don't have a logger at the time this is run
      // (which is why we don't use printTrace here)
      print('Unable to locate flutter root: $error');
    }
    return '.';
  }

  @override
  Future<dynamic> run(Iterable<String> args) {
    // Have an invocation of 'build' print out it's sub-commands.
    if (args.length == 1 && args.first == 'build')
      args = <String>['build', '-h'];

    return super.run(args).then((dynamic result) {
      return result;
    }).whenComplete(() {
      logger.flush();
    });
  }

  @override
  Future<int> runCommand(ArgResults globalResults) {
    _globalResults = globalResults;

    // Check for verbose.
    if (globalResults['verbose'])
      context[Logger] = new VerboseLogger();

    if (globalResults.wasParsed('color'))
      logger.supportsColor = globalResults['color'];

    // we must set ArtifactStore.flutterRoot early because other features use it
    // (e.g. enginePath's initialiser uses it)
    ArtifactStore.flutterRoot = path.normalize(path.absolute(globalResults['flutter-root']));
    PackageMap.instance = new PackageMap(path.normalize(path.absolute(
      globalResults.wasParsed('packages') ? globalResults['packages'] : '.packages'
    )));

    // See if the user specified a specific device.
    deviceManager.specifiedDeviceId = globalResults['device-id'];

    // Set up the tooling configuration.
    if (enginePath != null) {
      ToolConfiguration.instance.engineSrcPath = enginePath;

      if (globalResults.wasParsed('engine-release'))
        ToolConfiguration.instance.engineRelease = globalResults['engine-release'];
      if (globalResults.wasParsed('engine-debug'))
        ToolConfiguration.instance.engineRelease = !globalResults['engine-debug'];
    }

    // The Android SDK could already have been set by tests.
    if (!context.isSet(AndroidSdk)) {
      if (enginePath != null) {
        context[AndroidSdk] = new AndroidSdk('$enginePath/third_party/android_tools/sdk');
      } else {
        context[AndroidSdk] = AndroidSdk.locateAndroidSdk();
      }
    }

    if (globalResults['version']) {
      flutterUsage.sendCommand('version');
      printStatus(FlutterVersion.getVersion(ArtifactStore.flutterRoot).toString());
      return new Future<int>.value(0);
    }

    return super.runCommand(globalResults);
  }

  String _tryEnginePath(String enginePath) {
    if (FileSystemEntity.isDirectorySync(path.join(enginePath, 'out')))
      return enginePath;
    return null;
  }

  String _findEnginePath(ArgResults globalResults) {
    String engineSourcePath = globalResults['engine-src-path'] ?? Platform.environment[kFlutterEngineEnvironmentVariableName];
    bool isDebug = globalResults['engine-debug'];
    bool isRelease = globalResults['engine-release'];

    if (engineSourcePath == null && (isDebug || isRelease)) {
      try {
        Uri engineUri = PackageMap.instance.map[kFlutterEnginePackageName];
        engineSourcePath = path.dirname(path.dirname(path.dirname(path.dirname(engineUri.path))));
        bool dirExists = FileSystemEntity.isDirectorySync(path.join(engineSourcePath, 'out'));
        if (engineSourcePath == '/' || engineSourcePath.isEmpty || !dirExists)
          engineSourcePath = null;
      } on FileSystemException { } on FormatException { }

      if (engineSourcePath == null)
        engineSourcePath = _tryEnginePath(path.join(ArtifactStore.flutterRoot, '../engine/src'));

      if (engineSourcePath == null) {
        printError('Unable to detect local Flutter engine build directory.\n'
            'Either specify a dependency_override for the $kFlutterEnginePackageName package in your pubspec.yaml and\n'
            'ensure --package-root is set if necessary, or set the \$$kFlutterEngineEnvironmentVariableName environment variable, or\n'
            'use --engine-src-path to specify the path to the root of your flutter/engine repository.');
        throw new ProcessExit(2);
      }
    }

    if (engineSourcePath != null && _tryEnginePath(engineSourcePath) == null) {
      printError('Unable to detect a Flutter engine build directory in $engineSourcePath.\n'
          'Please ensure that $engineSourcePath is a Flutter engine \'src\' directory and that\n'
          'you have compiled the engine in that directory, which should produce an \'out\' directory');
      throw new ProcessExit(2);
    }

    return engineSourcePath;
  }

  List<BuildConfiguration> _createBuildConfigurations(ArgResults globalResults) {
    bool isDebug = globalResults['engine-debug'];
    bool isRelease = globalResults['engine-release'];
    HostPlatform hostPlatform = getCurrentHostPlatform();
    TargetPlatform hostPlatformAsTarget = getCurrentHostPlatformAsTarget();

    List<BuildConfiguration> configs = <BuildConfiguration>[];

    if (enginePath == null) {
      configs.add(new BuildConfiguration.prebuilt(
        hostPlatform: hostPlatform,
        targetPlatform: TargetPlatform.android_arm
      ));

      configs.add(new BuildConfiguration.prebuilt(
        hostPlatform: hostPlatform,
        targetPlatform: TargetPlatform.android_x64
      ));

      if (hostPlatform == HostPlatform.linux_x64) {
        configs.add(new BuildConfiguration.prebuilt(
          hostPlatform: HostPlatform.linux_x64,
          targetPlatform: TargetPlatform.linux_x64,
          testable: true
        ));
      }

      if (hostPlatform == HostPlatform.darwin_x64) {
        configs.add(new BuildConfiguration.prebuilt(
          hostPlatform: HostPlatform.darwin_x64,
          targetPlatform: TargetPlatform.ios
        ));
      }
    } else {
      if (!FileSystemEntity.isDirectorySync(enginePath))
        printError('$enginePath is not a valid directory');

      if (!isDebug && !isRelease)
        isDebug = true;

      if (isDebug) {
        configs.add(new BuildConfiguration.local(
          type: BuildType.debug,
          hostPlatform: hostPlatform,
          targetPlatform: TargetPlatform.android_arm,
          enginePath: enginePath,
          buildPath: globalResults['android-debug-build-path']
        ));

        configs.add(new BuildConfiguration.local(
          type: BuildType.debug,
          hostPlatform: hostPlatform,
          targetPlatform: hostPlatformAsTarget,
          enginePath: enginePath,
          buildPath: globalResults['host-debug-build-path'],
          testable: true
        ));

        if (Platform.isMacOS) {
          configs.add(new BuildConfiguration.local(
            type: BuildType.debug,
            hostPlatform: hostPlatform,
            targetPlatform: TargetPlatform.ios,
            enginePath: enginePath,
            buildPath: globalResults['ios-debug-build-path']
          ));

          configs.add(new BuildConfiguration.local(
            type: BuildType.debug,
            hostPlatform: hostPlatform,
            targetPlatform: TargetPlatform.ios,
            enginePath: enginePath,
            buildPath: globalResults['ios-sim-debug-build-path']
          ));
        }
      }

      if (isRelease) {
        configs.add(new BuildConfiguration.local(
          type: BuildType.release,
          hostPlatform: hostPlatform,
          targetPlatform: TargetPlatform.android_arm,
          enginePath: enginePath,
          buildPath: globalResults['android-release-build-path']
        ));

        configs.add(new BuildConfiguration.local(
          type: BuildType.release,
          hostPlatform: hostPlatform,
          targetPlatform: hostPlatformAsTarget,
          enginePath: enginePath,
          buildPath: globalResults['host-release-build-path'],
          testable: true
        ));

        if (Platform.isMacOS) {
          configs.add(new BuildConfiguration.local(
            type: BuildType.release,
            hostPlatform: hostPlatform,
            targetPlatform: TargetPlatform.ios,
            enginePath: enginePath,
            buildPath: globalResults['ios-release-build-path']
          ));

          configs.add(new BuildConfiguration.local(
            type: BuildType.release,
            hostPlatform: hostPlatform,
            targetPlatform: TargetPlatform.ios,
            enginePath: enginePath,
            buildPath: globalResults['ios-sim-release-build-path']
          ));
        }
      }
    }

    return configs;
  }

  static void initFlutterRoot() {
    if (ArtifactStore.flutterRoot == null)
      ArtifactStore.flutterRoot = _defaultFlutterRoot;
  }

  /// Get all pub packages in the Flutter repo.
  List<Directory> getRepoPackages() {
    return _gatherProjectPaths(path.absolute(ArtifactStore.flutterRoot))
      .map((String dir) => new Directory(dir))
      .toList();
  }

  static List<String> _gatherProjectPaths(String rootPath) {
    if (FileSystemEntity.isFileSync(path.join(rootPath, '.dartignore')))
      return <String>[];

    if (FileSystemEntity.isFileSync(path.join(rootPath, 'pubspec.yaml')))
      return <String>[rootPath];

    return new Directory(rootPath)
      .listSync(followLinks: false)
      .expand((FileSystemEntity entity) {
        return entity is Directory ? _gatherProjectPaths(entity.path) : <String>[];
      })
      .toList();
  }
}
