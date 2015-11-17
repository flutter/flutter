// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

import '../artifacts.dart';
import '../build_configuration.dart';
import '../process.dart';
import 'flutter_command.dart';

final Logger _logging = new Logger('flutter_tools.run_mojo');

class RunMojoCommand extends FlutterCommand {
  final String name = 'run_mojo';
  final String description = 'Run a Flutter app in mojo.';

  RunMojoCommand() {
    argParser.addFlag('android', negatable: false, help: 'Run on an Android device');
    argParser.addFlag('checked', negatable: false, help: 'Run Flutter in checked mode');
    argParser.addFlag('mojo-debug', negatable: false, help: 'Use Debug build of mojo');
    argParser.addFlag('mojo-release', negatable: false, help: 'Use Release build of mojo (default)');

    argParser.addOption('app', defaultsTo: 'app.flx');
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
    TargetPlatform target = getCurrentHostPlatformAsTarget();
    for (BuildConfiguration config in buildConfigurations) {
      if (config.targetPlatform == target) {
        result = config;
        break;
      }
    }
    return result;
  }

  Future<List<String>> _getShellConfig() async {
    List<String> args = <String>[];

    final bool useDevtools = _useDevtools();
    final String command = useDevtools ? _getDevtoolsPath() : _getMojoShellPath();
    args.add(command);

    if (argResults['android']) {
      args.add('--android');
      final String cloudStorageBaseUrl = ArtifactStore.getCloudStorageBaseUrl('shell', 'android-arm');
      final String appPath = _makePathAbsolute(argResults['app']);
      final String appName = path.basename(appPath);
      final String appDir = path.dirname(appPath);
      args.add('http://app/$appName');
      args.add('--map-origin=http://app/=$appDir');
      args.add('--map-origin=http://flutter/=$cloudStorageBaseUrl');
      args.add('--url-mappings=mojo:flutter=http://flutter/flutter.mojo');
    } else {
      final String appPath = _makePathAbsolute(argResults['app']);
      String flutterPath;
      BuildConfiguration config = _getCurrentHostConfig();
      if (config == null || config.type == BuildType.prebuilt) {
        Artifact artifact = ArtifactStore.getArtifact(type: ArtifactType.mojo, targetPlatform: TargetPlatform.linux);
        flutterPath = _makePathAbsolute(await ArtifactStore.getPath(artifact));
      } else {
        String localPath = path.join(config.buildDir, 'flutter.mojo');
        flutterPath = _makePathAbsolute(localPath);
      }
      args.add('file://$appPath');
      args.add('--url-mappings=mojo:flutter=file://$flutterPath');
    }

    if (useDevtools) {
      final String buildFlag = argResults['mojo-debug'] ? '--debug' : '--release';
      args.add(buildFlag);
      if (_logging.level <= Level.INFO) {
        args.add('--verbose');
        if (_logging.level <= Level.FINE) {
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
      _logging.severe('Must specify either --mojo-path or --devtools-path.');
      return 1;
    }

    if (argResults['mojo-debug'] && argResults['mojo-release']) {
      _logging.severe('Cannot specify both --mojo-debug and --mojo-release');
      return 1;
    }

    return await runCommandAndStreamOutput(await _getShellConfig());
  }

}
