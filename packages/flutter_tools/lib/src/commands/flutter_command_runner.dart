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

final Logger _logging = new Logger('sky_tools.flutter_command_runner');

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

    argParser.addSeparator('Global build selection options:');
    argParser.addFlag('debug',
        negatable: false,
        help:
            'Set this if you are building Flutter locally and want to use the debug build products. '
            'When set, attempts to automaticaly determine engine-src-path if engine-src-path is '
            'not set. Not normally required.');
    argParser.addFlag('release',
        negatable: false,
        help:
            'Set this if you are building Flutter locally and want to use the release build products. '
            'When set, attempts to automaticaly determine engine-src-path if engine-src-path is '
            'not set. Note that release is not compatible with the listen command '
            'on iOS devices and simulators. Not normally required.');
    argParser.addFlag('local-build',
        negatable: false,
        help:
            'Automatically detect your engine src directory from an overridden Flutter package.'
            'Useful if you are building Flutter locally and are using a dependency_override for'
            'the Flutter package that points to your engine src directory.');
    argParser.addOption('engine-src-path',
        help:
            'Path to your engine src directory, if you are building Flutter locally. '
            'Ignored if neither debug nor release is set. Not normally required.');
    argParser.addOption('android-debug-build-path',
        help:
            'Path to your Android Debug out directory, if you are building Flutter locally. '
            'This path is relative to engine-src-path. Not normally required.',
        defaultsTo: 'out/android_Debug/');
    argParser.addOption('android-release-build-path',
        help:
            'Path to your Android Release out directory, if you are building Flutter locally. '
            'This path is relative to engine-src-path. Not normally required.',
        defaultsTo: 'out/android_Release/');
    argParser.addOption('ios-debug-build-path',
        help:
            'Path to your iOS Debug out directory, if you are building Flutter locally. '
            'This path is relative to engine-src-path. Not normally required.',
        defaultsTo: 'out/ios_Debug/');
    argParser.addOption('ios-release-build-path',
        help:
            'Path to your iOS Release out directory, if you are building Flutter locally. '
            'This path is relative to engine-src-path. Not normally required.',
        defaultsTo: 'out/ios_Release/');
    argParser.addOption('ios-sim-debug-build-path',
        help:
            'Path to your iOS Simulator Debug out directory, if you are building Sky locally. '
            'This path is relative to engine-src-path. Not normally required.',
        defaultsTo: 'out/ios_sim_Debug/');
    argParser.addOption('ios-sim-release-build-path',
        help:
            'Path to your iOS Simulator Release out directory, if you are building Sky locally. '
            'This path is relative to engine-src-path. Not normally required.',
        defaultsTo: 'out/ios_sim_Release/');
    argParser.addOption('package-root',
        help: 'Path to your packages directory.', defaultsTo: 'packages');
  }

  List<BuildConfiguration> get buildConfigurations {
    if (_buildConfigurations == null)
      _buildConfigurations = _createBuildConfigurations(_globalResults);
    return _buildConfigurations;
  }
  List<BuildConfiguration> _buildConfigurations;

  ArgResults _globalResults;

  Future<int> runCommand(ArgResults globalResults) {
    if (globalResults['verbose'])
      Logger.root.level = Level.INFO;

    if (globalResults['very-verbose'])
      Logger.root.level = Level.FINE;

    _globalResults = globalResults;
    ArtifactStore.packageRoot = globalResults['package-root'];

    return super.runCommand(globalResults);
  }

  List<BuildConfiguration> _createBuildConfigurations(ArgResults globalResults) {
    if (!FileSystemEntity.isDirectorySync(ArtifactStore.packageRoot)) {
      String message = '${ArtifactStore.packageRoot} is not a valid directory.';
      if (ArtifactStore.packageRoot == 'packages') {
        if (FileSystemEntity.isFileSync('pubspec.yaml'))
          message += '\nDid you run `pub get` in this directory?';
        else
          message += '\nDid you run this command from the same directory as your pubspec.yaml file?';
      }
      _logging.severe(message);
      exit(2);
    }

    String enginePath = globalResults['engine-src-path'];
    bool isDebug = globalResults['debug'];
    bool isRelease = globalResults['release'];

    if (enginePath == null && globalResults['local-build']) {
      Directory flutterDir = new Directory(path.join(globalResults['package-root'], 'flutter'));
      String realFlutterPath = flutterDir.resolveSymbolicLinksSync();

      enginePath = path.dirname(path.dirname(path.dirname(path.dirname(realFlutterPath))));
      if (enginePath == '/' || enginePath.isEmpty)
        enginePath = null;
    }

    List<BuildConfiguration> configs = <BuildConfiguration>[];

    if (enginePath == null) {
      configs.add(new BuildConfiguration.prebuilt(platform: BuildPlatform.android));
    } else {
      if (!FileSystemEntity.isDirectorySync(enginePath))
        _logging.warning('$enginePath is not a valid directory');

      if (!isDebug && !isRelease)
        isDebug = true;

      if (isDebug) {
        configs.add(new BuildConfiguration.local(
          type: BuildType.debug,
          platform: BuildPlatform.android,
          enginePath: enginePath,
          buildPath: globalResults['android-debug-build-path']
        ));

        if (Platform.isMacOS) {
          configs.add(new BuildConfiguration.local(
            type: BuildType.debug,
            platform: BuildPlatform.iOS,
            enginePath: enginePath,
            buildPath: globalResults['ios-debug-build-path']
          ));

          configs.add(new BuildConfiguration.local(
            type: BuildType.debug,
            platform: BuildPlatform.iOSSimulator,
            enginePath: enginePath,
            buildPath: globalResults['ios-sim-debug-build-path']
          ));
        }
      }

      if (isRelease) {
        configs.add(new BuildConfiguration.local(
          type: BuildType.release,
          platform: BuildPlatform.android,
          enginePath: enginePath,
          buildPath: globalResults['android-release-build-path']
        ));

        if (Platform.isMacOS) {
          configs.add(new BuildConfiguration.local(
            type: BuildType.release,
            platform: BuildPlatform.iOS,
            enginePath: enginePath,
            buildPath: globalResults['ios-release-build-path']
          ));

          configs.add(new BuildConfiguration.local(
            type: BuildType.release,
            platform: BuildPlatform.iOSSimulator,
            enginePath: enginePath,
            buildPath: globalResults['ios-sim-release-build-path']
          ));
        }
      }
    }

    return configs;
  }
}
