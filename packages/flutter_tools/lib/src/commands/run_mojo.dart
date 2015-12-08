// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

import '../artifacts.dart';
import '../base/logging.dart';
import '../base/process.dart';
import '../build_configuration.dart';
import '../runner/flutter_command.dart';
import 'build.dart';
import 'start.dart';

const String _kDefaultBundlePath = 'build/app.flx';

class RunMojoCommand extends FlutterCommand {
  final String name = 'run_mojo';
  final String description = 'Run a Flutter app in mojo.';

  RunMojoCommand() {
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

  bool get requiresProjectRoot => false;

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
    final mojoBuildType = argResults['mojo-debug']  ? 'Debug' : 'Release';
    return _makePathAbsolute(path.join(argResults['mojo-path'], 'out', mojoBuildType, 'mojo_shell'));
  }

  BuildConfiguration _getCurrentHostConfig() {
    BuildConfiguration result;
    TargetPlatform target = argResults['android'] ?
      TargetPlatform.android : getCurrentHostPlatformAsTarget();
    for (BuildConfiguration config in buildConfigurations) {
      if (config.targetPlatform == target) {
        result = config;
        break;
      }
    }
    return result;
  }

  Future<List<String>> _getShellConfig(String bundlePath) async {
    List<String> args = <String>[];

    final bool useDevtools = _useDevtools();
    final String command = useDevtools ? _getDevtoolsPath() : _getMojoShellPath();
    args.add(command);

    BuildConfiguration config = _getCurrentHostConfig();
    final String appPath = _makePathAbsolute(bundlePath);

    String flutterPath;
    if (config == null || config.type == BuildType.prebuilt) {
      TargetPlatform targetPlatform = argResults['android'] ? TargetPlatform.android : TargetPlatform.linux;
      Artifact artifact = ArtifactStore.getArtifact(type: ArtifactType.mojo, targetPlatform: targetPlatform);
      flutterPath = _makePathAbsolute(await ArtifactStore.getPath(artifact));
    } else {
      String localPath = path.join(config.buildDir, 'flutter.mojo');
      flutterPath = _makePathAbsolute(localPath);
    }

    if (argResults['android']) {
      args.add('--android');
      final String appName = path.basename(appPath);
      final String appDir = path.dirname(appPath);
      args.add('http://app/$appName');
      args.add('--map-origin=http://app/=$appDir');

      final String flutterName = path.basename(flutterPath);
      final String flutterDir = path.dirname(flutterPath);
      args.add('--map-origin=http://flutter/=$flutterDir');
      args.add('--url-mappings=mojo:flutter=http://flutter/$flutterName');
    } else {
      args.add('file://$appPath');
      args.add('--url-mappings=mojo:flutter=file://$flutterPath');
    }

    if (useDevtools) {
      final String buildFlag = argResults['mojo-debug'] ? '--debug' : '--release';
      args.add(buildFlag);
      if (logging.level <= Level.INFO) {
        args.add('--verbose');
        if (logging.level <= Level.FINE) {
          args.add('--verbose');
        }
      }
    }

    if (argResults['checked']) {
      args.add('--args-for=mojo:flutter --enable-checked-mode');
    }

    args.addAll(argResults.rest);
    print(args);
    return args;
  }

  @override
  Future<int> runInProject() async {
    if ((argResults['mojo-path'] == null && argResults['devtools-path'] == null) || (argResults['mojo-path'] != null && argResults['devtools-path'] != null)) {
      logging.severe('Must specify either --mojo-path or --devtools-path.');
      return 1;
    }

    if (argResults['mojo-debug'] && argResults['mojo-release']) {
      logging.severe('Cannot specify both --mojo-debug and --mojo-release');
      return 1;
    }

    await downloadToolchain();

    String bundlePath = argResults['app'];
    if (bundlePath == null) {
      bundlePath = _kDefaultBundlePath;

      String mainPath = StartCommand.findMainDartFile(argResults['target']);

      BuildCommand builder = new BuildCommand();
      builder.inheritFromParent(this);
      int result = await builder.build(mainPath: mainPath, outputPath: bundlePath);
      if (result != 0)
        return result;
    }

    return await runCommandAndStreamOutput(await _getShellConfig(bundlePath));
  }
}
