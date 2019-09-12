// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;
import 'package:args/args.dart' as args;
import 'package:path/path.dart' as pathlib;

/// Contains various environment variables, such as common file paths and command-line options.
Environment get environment {
  _environment ??= Environment();
  return _environment;
}
Environment _environment;

args.ArgParser get _argParser {
  return args.ArgParser()
    ..addMultiOption(
      'target',
      abbr: 't',
      help: 'The path to the target to run. When omitted, runs all targets.',
    )
    ..addMultiOption(
      'shard',
      abbr: 's',
      help: 'The category of tasks to run.',
    )
    ..addFlag(
      'debug',
      help: 'Pauses the browser before running a test, giving you an '
        'opportunity to add breakpoints or inspect loaded code before '
        'running the code.',
    )
    ..addOption(
      'chrome-version',
      help: 'The Chrome version to use while running tests. If the requested '
        'version has not been installed, it will be downloaded and installed '
        'automatically. A specific Chrome build version number, such as 695653 '
        'this use that version of Chrome. Value "latest" will use the latest '
        'available build of Chrome, installing it if necessary. Value "system" '
        'will use the manually installed version of Chrome on this computer.',
    );
}

/// Contains various environment variables, such as common file paths and command-line options.
class Environment {
  /// Command-line arguments.
  static List<String> commandLineArguments;

  factory Environment() {
    if (commandLineArguments == null) {
      io.stderr.writeln('Command-line arguments not set.');
      io.exit(1);
    }

    final args.ArgResults options = _argParser.parse(commandLineArguments);
    final List<String> shards = options['shard'];
    final bool isDebug = options['debug'];
    final List<String> targets = options['target'];

    final io.File self = io.File.fromUri(io.Platform.script);
    final io.Directory engineSrcDir = self.parent.parent.parent.parent.parent;
    final io.Directory outDir = io.Directory(pathlib.join(engineSrcDir.path, 'out'));
    final io.Directory hostDebugUnoptDir = io.Directory(pathlib.join(outDir.path, 'host_debug_unopt'));
    final io.Directory dartSdkDir = io.Directory(pathlib.join(hostDebugUnoptDir.path, 'dart-sdk'));
    final io.Directory webUiRootDir = io.Directory(pathlib.join(engineSrcDir.path, 'flutter', 'lib', 'web_ui'));

    for (io.Directory expectedDirectory in <io.Directory>[engineSrcDir, outDir, hostDebugUnoptDir, dartSdkDir, webUiRootDir]) {
      if (!expectedDirectory.existsSync()) {
        io.stderr.writeln('$expectedDirectory does not exist.');
        io.exit(1);
      }
    }

    final String pinnedChromeVersion = io.File(pathlib.join(webUiRootDir.path, 'dev', 'chrome.lock')).readAsStringSync().trim();
    final String chromeVersion = options['chrome-version'] ?? pinnedChromeVersion;

    return Environment._(
      self: self,
      webUiRootDir: webUiRootDir,
      engineSrcDir: engineSrcDir,
      outDir: outDir,
      hostDebugUnoptDir: hostDebugUnoptDir,
      dartSdkDir: dartSdkDir,
      requestedShards: shards,
      isDebug: isDebug,
      targets: targets,
      chromeVersion: chromeVersion,
    );
  }

  Environment._({
    this.self,
    this.webUiRootDir,
    this.engineSrcDir,
    this.outDir,
    this.hostDebugUnoptDir,
    this.dartSdkDir,
    this.requestedShards,
    this.isDebug,
    this.targets,
    this.chromeVersion,
  });

  /// The Dart script that's currently running.
  final io.File self;

  /// Path to the "web_ui" package sources.
  final io.Directory webUiRootDir;

  /// Path to the engine's "src" directory.
  final io.Directory engineSrcDir;

  /// Path to the engine's "out" directory.
  ///
  /// This is where you'll find the ninja output, such as the Dart SDK.
  final io.Directory outDir;

  /// The "host_debug_unopt" build of the Dart SDK.
  final io.Directory hostDebugUnoptDir;

  /// The root of the Dart SDK.
  final io.Directory dartSdkDir;

  /// Shards specified on the command-line.
  final List<String> requestedShards;

  /// Whether to start the browser in debug mode.
  ///
  /// In this mode the browser pauses before running the test to allow
  /// you set breakpoints or inspect the code.
  final bool isDebug;

  /// Paths to targets to run, e.g. a single test.
  final List<String> targets;

  /// The Chrome version used for testing.
  ///
  /// The value must be one of:
  ///
  /// - "system", which indicates the Chrome installed on the local machine.
  /// - "latest", which indicates the latest available Chrome build specified by:
  ///   https://www.googleapis.com/download/storage/v1/b/chromium-browser-snapshots/o/Linux_x64%2FLAST_CHANGE?alt=media
  /// - A build number pointing at a pre-built version of Chrome available at:
  ///   https://commondatastorage.googleapis.com/chromium-browser-snapshots/index.html?prefix=Linux_x64/
  ///
  /// The "system" Chrome is assumed to be already properly installed and will be invoked directly.
  ///
  /// The "latest" or a specific build number will be downloaded and cached in [webUiDartToolDir].
  final String chromeVersion;

  /// The "dart" executable file.
  String get dartExecutable => pathlib.join(dartSdkDir.path, 'bin', 'dart');

  /// The "pub" executable file.
  String get pubExecutable => pathlib.join(dartSdkDir.path, 'bin', 'pub');

  /// The "dart2js" executable file.
  String get dart2jsExecutable => pathlib.join(dartSdkDir.path, 'bin', 'dart2js');

  /// Path to where github.com/flutter/engine is checked out inside the engine workspace.
  io.Directory get flutterDirectory => io.Directory(pathlib.join(engineSrcDir.path, 'flutter'));
  io.Directory get webSdkRootDir => io.Directory(pathlib.join(
    flutterDirectory.path,
    'web_sdk',
  ));

  /// Path to the "web_engine_tester" package.
  io.Directory get goldenTesterRootDir => io.Directory(pathlib.join(
    webSdkRootDir.path,
    'web_engine_tester',
  ));

  /// Path to the "build" directory, generated by "package:build_runner".
  ///
  /// This is where compiled output goes.
  io.Directory get webUiBuildDir => io.Directory(pathlib.join(
    webUiRootDir.path,
    'build',
  ));

  /// Path to the ".dart_tool" directory, generated by various Dart tools.
  io.Directory get webUiDartToolDir => io.Directory(pathlib.join(
    webUiRootDir.path,
    '.dart_tool',
  ));
}
