// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../base/process.dart';
import '../build_info.dart';
import '../cache.dart';
import '../flx.dart' as flx;
import '../globals.dart';
import '../resident_runner.dart';
import '../runner/flutter_command.dart';

String get _defaultBundlePath => path.join(getBuildDirectory(), 'app.flx');

class RunMojoCommand extends FlutterCommand {
  RunMojoCommand({ this.hidden: false }) {
    argParser.addFlag('android', negatable: false, help: 'Run on an Android device');
    argParser.addFlag('checked', negatable: false, help: 'Run Flutter in checked mode');
    argParser.addFlag('mojo-debug', negatable: false, help: 'Use Debug build of mojo');
    argParser.addFlag('mojo-release', negatable: false, help: 'Use Release build of mojo (default)');

    argParser.addOption('target',
        defaultsTo: '',
        abbr: 't',
        help: 'Target app path or filename to start.');
    argParser.addOption('app', help: 'Run this Flutter app instead of building the target.');
    argParser.addOption('mojo-path', help: 'Path to directory containing mojo_shell and services.');
    argParser.addOption('devtools-path', help: 'Path to mojo devtools\' mojo_run command.');
  }

  @override
  final String name = 'run_mojo';

  @override
  final String description = 'Run a Flutter app in mojo (from github.com/domokit/mojo).';

  @override
  final bool hidden;

  // TODO(abarth): Why not use path.absolute?
  String _makePathAbsolute(String relativePath) {
    File file = new File(relativePath);
    if (!file.existsSync()) {
      throw new Exception('Path "$relativePath" does not exist');
    }
    return file.absolute.path;
  }

  bool _useDevtools() {
    if (argResults['android'] || argResults['devtools-path'] != null) {
      return true;
    }
    return false;
  }

  String _getDevtoolsPath() {
    if (argResults['devtools-path'] != null) {
      return _makePathAbsolute(argResults['devtools-path']);
    }
    return _makePathAbsolute(path.join(argResults['mojo-path'], 'mojo', 'devtools', 'common', 'mojo_run'));
  }

  String _getMojoShellPath() {
    final String mojoBuildType = argResults['mojo-debug']  ? 'Debug' : 'Release';
    return _makePathAbsolute(path.join(argResults['mojo-path'], 'out', mojoBuildType, 'mojo_shell'));
  }

  Future<List<String>> _getShellConfig(String targetApp) async {
    List<String> args = <String>[];

    final bool useDevtools = _useDevtools();
    final String command = useDevtools ? _getDevtoolsPath() : _getMojoShellPath();
    args.add(command);

    TargetPlatform targetPlatform = argResults['android'] ? TargetPlatform.android_arm : TargetPlatform.linux_x64;
    String flutterPath = path.join(tools.getEngineArtifactsDirectory(targetPlatform, BuildMode.debug).path, 'flutter.mojo');

    if (argResults['android'])
      args.add('--android');

    final Uri appUri = Uri.parse(targetApp);
    if (appUri.scheme.isEmpty || appUri.scheme == 'file') {
      final String appPath = _makePathAbsolute(targetApp);
      if (argResults['android']) {
        final String appName = path.basename(appPath);
        final String appDir = path.dirname(appPath);
        args.add('mojo:launcher http://app/$appName');
        args.add('--map-origin=http://app/=$appDir');
      } else {
        args.add('mojo:launcher file://$appPath');
      }
    } else {
      args.add('mojo:launcher $targetApp');
    }

    // Add url-mapping for mojo:flutter.
    if (argResults['android']) {
      final String flutterName = path.basename(flutterPath);
      final String flutterDir = path.dirname(flutterPath);
      args.add('--map-origin=http://flutter/=$flutterDir');
      args.add('--url-mappings=mojo:flutter=http://flutter/$flutterName');
    } else {
      args.add('--url-mappings=mojo:flutter=file://$flutterPath');
    }

    if (useDevtools) {
      final String buildFlag = argResults['mojo-debug'] ? '--debug' : '--release';
      args.add(buildFlag);
      if (logger.isVerbose)
        args.add('--verbose');
    }

    if (argResults['checked'])
      args.add('--args-for=mojo:flutter --enable-checked-mode');

    args.addAll(argResults.rest);
    printStatus('$args');
    return args;
  }

  @override
  Future<int> runCommand() async {
    if ((argResults['mojo-path'] == null && argResults['devtools-path'] == null) || (argResults['mojo-path'] != null && argResults['devtools-path'] != null)) {
      printError('Must specify either --mojo-path or --devtools-path.');
      return 1;
    }

    if (argResults['mojo-debug'] && argResults['mojo-release']) {
      printError('Cannot specify both --mojo-debug and --mojo-release');
      return 1;
    }

    String targetApp = argResults['app'];
    if (targetApp == null) {
      targetApp = _defaultBundlePath;

      String mainPath = findMainDartFile(argResults['target']);

      int result = await flx.build(
        mainPath: mainPath,
        outputPath: targetApp
      );
      if (result != 0)
        return result;
    }

    Cache.releaseLockEarly();

    return await runCommandAndStreamOutput(await _getShellConfig(targetApp));
  }
}
