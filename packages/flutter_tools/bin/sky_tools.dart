// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:logging/logging.dart';
import 'package:sky_tools/src/application_package.dart';
import 'package:sky_tools/src/artifacts.dart';
import 'package:sky_tools/src/build.dart';
import 'package:sky_tools/src/cache.dart';
import 'package:sky_tools/src/init.dart';
import 'package:sky_tools/src/install.dart';
import 'package:sky_tools/src/listen.dart';
import 'package:sky_tools/src/logs.dart';
import 'package:sky_tools/src/run_mojo.dart';
import 'package:sky_tools/src/start.dart';
import 'package:sky_tools/src/stop.dart';
import 'package:sky_tools/src/trace.dart';

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
            'Set this if you are building Sky locally and want to use the debug build products. '
            'When set, attempts to automaticaly determine sky-src-path if sky-src-path is '
            'not set. Not normally required.');
    argParser.addFlag('release',
        negatable: false,
        help:
            'Set this if you are building Sky locally and want to use the release build products. '
            'When set, attempts to automaticaly determine sky-src-path if sky-src-path is '
            'not set. Note that release is not compatible with the listen command '
            'on iOS devices and simulators. Not normally required.');
    argParser.addOption('sky-src-path',
        help:
            'Path to your Sky src directory, if you are building Sky locally. '
            'Ignored if neither debug nor release is set. Not normally required.');
    argParser.addOption('android-debug-build-path',
        help:
            'Path to your Android Debug out directory, if you are building Sky locally. '
            'This path is relative to sky-src-path. Not normally required.',
        defaultsTo: 'out/android_Debug/');
    argParser.addOption('android-release-build-path',
        help:
            'Path to your Android Release out directory, if you are building Sky locally. '
            'This path is relative to sky-src-path. Not normally required.',
        defaultsTo: 'out/android_Release/');
    argParser.addOption('ios-debug-build-path',
        help:
            'Path to your iOS Debug out directory, if you are building Sky locally. '
            'This path is relative to sky-src-path. Not normally required.',
        defaultsTo: 'out/ios_Debug/');
    argParser.addOption('ios-release-build-path',
        help:
            'Path to your iOS Release out directory, if you are building Sky locally. '
            'This path is relative to sky-src-path. Not normally required.',
        defaultsTo: 'out/ios_Release/');
    argParser.addOption('ios-sim-debug-build-path',
        help:
            'Path to your iOS Simulator Debug out directory, if you are building Sky locally. '
            'This path is relative to sky-src-path. Not normally required.',
        defaultsTo: 'out/ios_sim_Debug/');
    argParser.addOption('ios-sim-release-build-path',
        help:
            'Path to your iOS Simulator Release out directory, if you are building Sky locally. '
            'This path is relative to sky-src-path. Not normally required.',
        defaultsTo: 'out/ios_sim_Release/');
    argParser.addOption('package-root',
        help: 'Path to your packages directory.', defaultsTo: 'packages');
  }

  Future<int> runCommand(ArgResults topLevelResults) async {
    if (topLevelResults['verbose']) {
      Logger.root.level = Level.INFO;
    }

    if (topLevelResults['very-verbose']) {
      Logger.root.level = Level.FINE;
    }

    _setupPaths(topLevelResults);

    return super.runCommand(topLevelResults);
  }

  void _setupPaths(ArgResults results) {
    ArtifactStore.packageRoot = results['package-root'];
    if (results['debug'] || results['release']) {
      if (results['sky-src-path'] == null) {
        // TODO(iansf): Figure out how to get the default src path
        assert(false);
      }
      ApplicationPackageFactory.srcPath = results['sky-src-path'];
    } else {
      assert(false);
      // TODO(iansf): set paths up for commands using PREBUILT binaries
      // ApplicationPackageFactory.setBuildPath(BuildType.PREBUILT,
      //     BuildPlatform.android, results['android-debug-build-path']);
    }

    if (results['debug']) {
      ApplicationPackageFactory.defaultBuildType = BuildType.debug;
      ApplicationPackageFactory.setBuildPath(BuildType.debug,
          BuildPlatform.android, results['android-debug-build-path']);
      ApplicationPackageFactory.setBuildPath(
          BuildType.debug, BuildPlatform.iOS, results['ios-debug-build-path']);
      ApplicationPackageFactory.setBuildPath(BuildType.debug,
          BuildPlatform.iOSSimulator, results['ios-sim-debug-build-path']);
    }
    if (results['release']) {
      ApplicationPackageFactory.defaultBuildType = BuildType.release;
      ApplicationPackageFactory.setBuildPath(BuildType.release,
          BuildPlatform.android, results['android-release-build-path']);
      ApplicationPackageFactory.setBuildPath(BuildType.release,
          BuildPlatform.iOS, results['ios-release-build-path']);
      ApplicationPackageFactory.setBuildPath(BuildType.release,
          BuildPlatform.iOSSimulator, results['ios-sim-release-build-path']);
    }
  }
}

void main(List<String> args) {
  Logger.root.level = Level.WARNING;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.message}');
    if (rec.error != null) {
      print(rec.error);
    }
    if (rec.stackTrace != null) {
      print(rec.stackTrace);
    }
  });

  new FlutterCommandRunner()
    ..addCommand(new BuildCommand())
    ..addCommand(new CacheCommand())
    ..addCommand(new InitCommand())
    ..addCommand(new InstallCommand())
    ..addCommand(new ListenCommand())
    ..addCommand(new LogsCommand())
    ..addCommand(new RunMojoCommand())
    ..addCommand(new StartCommand())
    ..addCommand(new StopCommand())
    ..addCommand(new TraceCommand())
    ..run(args);
}
