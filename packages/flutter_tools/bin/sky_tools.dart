// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:sky_tools/src/build.dart';
import 'package:sky_tools/src/cache.dart';
import 'package:sky_tools/src/common.dart';
import 'package:sky_tools/src/init.dart';
import 'package:sky_tools/src/install.dart';
import 'package:sky_tools/src/run_mojo.dart';
import 'package:sky_tools/src/application_package.dart';

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

  Map<String, CommandHandler> handlers = {};

  ArgParser parser = new ArgParser();
  parser.addSeparator('basic options:');
  parser.addFlag('help',
      abbr: 'h', negatable: false, help: 'Display this help message.');
  parser.addFlag('verbose',
      abbr: 'v',
      negatable: false,
      help: 'Noisy logging, including all shell commands executed.');
  parser.addFlag('very-verbose',
      negatable: false,
      help: 'Very noisy logging, including the output of all '
          'shell commands executed.');

  parser.addSeparator('build selection options:');
  parser.addFlag('debug',
      negatable: false,
      help:
          'Set this if you are building Sky locally and want to use the debug build products. '
          'When set, attempts to automaticaly determine sky-src-path if sky-src-path is '
          'not set. Not normally required.');
  parser.addFlag('release',
      negatable: false,
      help:
          'Set this if you are building Sky locally and want to use the release build products. '
          'When set, attempts to automaticaly determine sky-src-path if sky-src-path is '
          'not set. Note that release is not compatible with the listen command '
          'on iOS devices and simulators. Not normally required.');
  parser.addOption('sky-src-path',
      help: 'Path to your Sky src directory, if you are building Sky locally. '
          'Ignored if neither debug nor release is set. Not normally required.');
  parser.addOption('android-debug-build-path',
      help:
          'Path to your Android Debug out directory, if you are building Sky locally. '
          'This path is relative to sky-src-path. Not normally required.',
      defaultsTo: 'out/android_Debug/');
  parser.addOption('android-release-build-path',
      help:
          'Path to your Android Release out directory, if you are building Sky locally. '
          'This path is relative to sky-src-path. Not normally required.',
      defaultsTo: 'out/android_Release/');
  parser.addOption('ios-debug-build-path',
      help:
          'Path to your iOS Debug out directory, if you are building Sky locally. '
          'This path is relative to sky-src-path. Not normally required.',
      defaultsTo: 'out/ios_Debug/');
  parser.addOption('ios-release-build-path',
      help:
          'Path to your iOS Release out directory, if you are building Sky locally. '
          'This path is relative to sky-src-path. Not normally required.',
      defaultsTo: 'out/ios_Release/');
  parser.addOption('ios-sim-debug-build-path',
      help:
          'Path to your iOS Simulator Debug out directory, if you are building Sky locally. '
          'This path is relative to sky-src-path. Not normally required.',
      defaultsTo: 'out/ios_sim_Debug/');
  parser.addOption('ios-sim-release-build-path',
      help:
          'Path to your iOS Simulator Release out directory, if you are building Sky locally. '
          'This path is relative to sky-src-path. Not normally required.',
      defaultsTo: 'out/ios_sim_Release/');

  parser.addSeparator('commands:');

  for (CommandHandler handler in [
    new BuildCommandHandler(),
    new CacheCommandHandler(),
    new InitCommandHandler(),
    new InstallCommandHandler(),
    new RunMojoCommandHandler(),
  ]) {
    parser.addCommand(handler.name, handler.parser);
    handlers[handler.name] = handler;
  }

  ArgResults results;

  try {
    results = parser.parse(args);
  } catch (e) {
    _printUsage(parser, handlers, e is FormatException ? e.message : '${e}');
    exit(1);
  }

  if (results['verbose']) {
    Logger.root.level = Level.INFO;
  }

  if (results['very-verbose']) {
    Logger.root.level = Level.FINE;
  }

  _setupPaths(results);

  if (results['help']) {
    _printUsage(parser, handlers);
  } else if (results.command != null) {
    handlers[results.command.name]
        .processArgResults(results.command)
        .then((int code) => exit(code))
        .catchError((e, stack) {
      print('Error running ' + results.command.name + ': $e');
      print(stack);
      exit(2);
    });
  } else {
    _printUsage(parser, handlers, 'No command specified.');
    exit(1);
  }
}

void _setupPaths(ArgResults results) {
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
    ApplicationPackageFactory.setBuildPath(BuildType.release, BuildPlatform.iOS,
        results['ios-release-build-path']);
    ApplicationPackageFactory.setBuildPath(BuildType.release,
        BuildPlatform.iOSSimulator, results['ios-sim-release-build-path']);
  }
}

void _printUsage(ArgParser parser, Map<String, CommandHandler> handlers,
    [String message]) {
  if (message != null) {
    print('${message}\n');
  }
  print('usage: sky_tools <command> [arguments]');
  print('');
  print(parser.usage);
  handlers.forEach((String command, CommandHandler handler) {
    print('  ${command.padRight(10)} ${handler.description}');
  });
}
