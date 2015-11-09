// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

import '../artifacts.dart';
import '../build_configuration.dart';
import '../process.dart';

final Logger _logging = new Logger('sky_tools.flutter_command_runner');

const String kFlutterRootEnvironmentVariableName = 'FLUTTER_ROOT'; // should point to //flutter/ (root of flutter/flutter repo)
const String kFlutterEngineEnvironmentVariableName = 'FLUTTER_ENGINE'; // should point to //engine/src/ (root of flutter/engine repo)
const String kSnapshotFileName = 'flutter_tools.snapshot'; // in //flutter/bin/cache/
const String kFlutterToolsScriptFileName = 'sky_tools.dart'; // in //flutter/packages/flutter_tools/bin/
const String kFlutterEnginePackageName = 'sky_engine';

class FlutterCommandRunner extends CommandRunner {
  FlutterCommandRunner()
      : super('flutter', 'Manage your Flutter app development.') {
    argParser.addFlag('verbose',
        abbr: 'v',
        negatable: false,
        help: 'Noisy logging, including all shell commands executed.');
    argParser.addFlag('very-verbose',
        negatable: false,
        help: 'Very noisy logging, including the output of all '
            'shell commands executed.');
    String packagesHelp;
    if (ArtifactStore.isPackageRootValid)
      packagesHelp = '\n(defaults to "${ArtifactStore.packageRoot}")';
    else
      packagesHelp = '\n(required, since the current directory does not contain a "packages" subdirectory)';
    argParser.addOption('package-root',
        help: 'Path to your packages directory.$packagesHelp');
    argParser.addOption('flutter-root',
        help: 'The root directory of the Flutter repository. Defaults to \$$kFlutterRootEnvironmentVariableName if set,\n'
              'otherwise defaults to a value derived from the location of this tool.', defaultsTo: defaultFlutterRoot);

    argParser.addOption('android-device-id',
        help: 'Serial number of the target Android device.');

    argParser.addSeparator('Local build selection options (not normally required):');
    argParser.addFlag('debug',
        negatable: false,
        help:
            'Set this if you are building Flutter locally and want to use the debug build products.\n'
            'Defaults to true if --engine-src-path is specified and --release is not, otherwise false.');
    argParser.addFlag('release',
        negatable: false,
        help:
            'Set this if you are building Flutter locally and want to use the release build products.\n'
            'The --release option is not compatible with the listen command on iOS devices and simulators.');
    argParser.addOption('engine-src-path',
        help:
            'Path to your engine src directory, if you are building Flutter locally.\n'
            'Defaults to \$$kFlutterEngineEnvironmentVariableName if set, otherwise defaults to the path given in your pubspec.yaml\n'
            'dependency_overrides for $kFlutterEnginePackageName, if any, or, failing that, tries to guess at the location\n'
            'based on the value of the --flutter-root option.');
    argParser.addOption('host-debug-build-path', hide: true,
        help:
            'Path to your host Debug out directory (i.e. the one that runs on your workstation, not a device), if you are building Flutter locally.\n'
            'This path is relative to --engine-src-path. Not normally required.',
        defaultsTo: 'out/Debug/');
    argParser.addOption('host-release-build-path', hide: true,
        help:
            'Path to your host Release out directory (i.e. the one that runs on your workstation, not a device), if you are building Flutter locally.\n'
            'This path is relative to --engine-src-path. Not normally required.',
        defaultsTo: 'out/Release/');
    argParser.addOption('android-debug-build-path', hide: true,
        help:
            'Path to your Android Debug out directory, if you are building Flutter locally.\n'
            'This path is relative to --engine-src-path. Not normally required.',
        defaultsTo: 'out/android_Debug/');
    argParser.addOption('android-release-build-path', hide: true,
        help:
            'Path to your Android Release out directory, if you are building Flutter locally.\n'
            'This path is relative to --engine-src-path. Not normally required.',
        defaultsTo: 'out/android_Release/');
    argParser.addOption('ios-debug-build-path', hide: true,
        help:
            'Path to your iOS Debug out directory, if you are building Flutter locally.\n'
            'This path is relative to --engine-src-path. Not normally required.',
        defaultsTo: 'out/ios_Debug/');
    argParser.addOption('ios-release-build-path', hide: true,
        help:
            'Path to your iOS Release out directory, if you are building Flutter locally.\n'
            'This path is relative to --engine-src-path. Not normally required.',
        defaultsTo: 'out/ios_Release/');
    argParser.addOption('ios-sim-debug-build-path', hide: true,
        help:
            'Path to your iOS Simulator Debug out directory, if you are building Flutter locally.\n'
            'This path is relative to --engine-src-path. Not normally required.',
        defaultsTo: 'out/ios_sim_Debug/');
    argParser.addOption('ios-sim-release-build-path', hide: true,
        help:
            'Path to your iOS Simulator Release out directory, if you are building Flutter locally.\n'
            'This path is relative to --engine-src-path. Not normally required.',
        defaultsTo: 'out/ios_sim_Release/');
  }

  List<BuildConfiguration> get buildConfigurations {
    if (_buildConfigurations == null)
      _buildConfigurations = _createBuildConfigurations(_globalResults);
    return _buildConfigurations;
  }
  List<BuildConfiguration> _buildConfigurations;

  ArgResults _globalResults;

  String get defaultFlutterRoot {
    String script = Platform.script.toFilePath();
    if (Platform.environment.containsKey(kFlutterRootEnvironmentVariableName))
      return Platform.environment[kFlutterRootEnvironmentVariableName];
    if (path.basename(script) == kSnapshotFileName)
      return path.dirname(path.dirname(path.dirname(script)));
    if (path.basename(script) == kFlutterToolsScriptFileName)
      return path.dirname(path.dirname(path.dirname(path.dirname(script))));
    return '.';
  }

  Future<int> runCommand(ArgResults globalResults) {
    if (globalResults['verbose'])
      Logger.root.level = Level.INFO;

    if (globalResults['very-verbose'])
      Logger.root.level = Level.FINE;

    _globalResults = globalResults;
    ArtifactStore.flutterRoot = globalResults['flutter-root'];
    if (globalResults.wasParsed('package-root'))
      ArtifactStore.packageRoot = globalResults['package-root'];

    return super.runCommand(globalResults);
  }

  List<BuildConfiguration> _createBuildConfigurations(ArgResults globalResults) {
    String enginePath = globalResults['engine-src-path'] ?? Platform.environment[kFlutterEngineEnvironmentVariableName];
    bool isDebug = globalResults['debug'];
    bool isRelease = globalResults['release'];
    HostPlatform hostPlatform = getCurrentHostPlatform();
    TargetPlatform hostPlatformAsTarget = getCurrentHostPlatformAsTarget();

    if (enginePath == null && (isDebug || isRelease)) {
      if (ArtifactStore.isPackageRootValid) {
        Directory engineDir = new Directory(path.join(ArtifactStore.packageRoot, kFlutterEnginePackageName));
        try {
          String realEnginePath = engineDir.resolveSymbolicLinksSync();
          enginePath = path.dirname(path.dirname(path.dirname(path.dirname(realEnginePath))));
          bool dirExists = FileSystemEntity.isDirectorySync(path.join(enginePath, 'out'));
          if (enginePath == '/' || enginePath.isEmpty || !dirExists)
            enginePath = null;
        } on FileSystemException { }
      }
      if (enginePath == null) {
        String tryEnginePath(String enginePath) {
          if (FileSystemEntity.isDirectorySync(path.join(enginePath, 'out')))
            return enginePath;
          return null;
        }
        enginePath = tryEnginePath(path.join(ArtifactStore.flutterRoot, '../engine/src'));
      }
      if (enginePath == null) {
        stderr.writeln('Unable to detect local Flutter engine build directory.\n'
            'Either specify a dependency_override for the $kFlutterEnginePackageName package in your pubspec.yaml and\n'
            'ensure --package-root is set if necessary, or set the \$$kFlutterEngineEnvironmentVariableName environment variable, or\n'
            'use --engine-src-path to specify the path to the root of your flutter/engine repository.');
        throw new ProcessExit(2);
      }
    }

    List<BuildConfiguration> configs = <BuildConfiguration>[];

    if (enginePath == null) {
      configs.add(new BuildConfiguration.prebuilt(
        hostPlatform: hostPlatform,
        targetPlatform: TargetPlatform.android,
        deviceId: globalResults['android-device-id']
      ));
    } else {
      if (!FileSystemEntity.isDirectorySync(enginePath))
        _logging.warning('$enginePath is not a valid directory');

      if (!isDebug && !isRelease)
        isDebug = true;

      if (isDebug) {
        configs.add(new BuildConfiguration.local(
          type: BuildType.debug,
          hostPlatform: hostPlatform,
          targetPlatform: hostPlatformAsTarget,
          enginePath: enginePath,
          buildPath: globalResults['host-debug-build-path'],
          testable: true
        ));

        configs.add(new BuildConfiguration.local(
          type: BuildType.debug,
          hostPlatform: hostPlatform,
          targetPlatform: TargetPlatform.android,
          enginePath: enginePath,
          buildPath: globalResults['android-debug-build-path'],
          deviceId: globalResults['android-device-id']
        ));

        if (Platform.isMacOS) {
          configs.add(new BuildConfiguration.local(
            type: BuildType.debug,
            hostPlatform: hostPlatform,
            targetPlatform: TargetPlatform.iOS,
            enginePath: enginePath,
            buildPath: globalResults['ios-debug-build-path']
          ));

          configs.add(new BuildConfiguration.local(
            type: BuildType.debug,
            hostPlatform: hostPlatform,
            targetPlatform: TargetPlatform.iOSSimulator,
            enginePath: enginePath,
            buildPath: globalResults['ios-sim-debug-build-path']
          ));
        }
      }

      if (isRelease) {
        configs.add(new BuildConfiguration.local(
          type: BuildType.release,
          hostPlatform: hostPlatform,
          targetPlatform: hostPlatformAsTarget,
          enginePath: enginePath,
          buildPath: globalResults['host-release-build-path'],
          testable: true
        ));

        configs.add(new BuildConfiguration.local(
          type: BuildType.release,
          hostPlatform: hostPlatform,
          targetPlatform: TargetPlatform.android,
          enginePath: enginePath,
          buildPath: globalResults['android-release-build-path'],
          deviceId: globalResults['android-device-id']
        ));

        if (Platform.isMacOS) {
          configs.add(new BuildConfiguration.local(
            type: BuildType.release,
            hostPlatform: hostPlatform,
            targetPlatform: TargetPlatform.iOS,
            enginePath: enginePath,
            buildPath: globalResults['ios-release-build-path']
          ));

          configs.add(new BuildConfiguration.local(
            type: BuildType.release,
            hostPlatform: hostPlatform,
            targetPlatform: TargetPlatform.iOSSimulator,
            enginePath: enginePath,
            buildPath: globalResults['ios-sim-release-build-path']
          ));
        }
      }
    }

    return configs;
  }
}
