// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

import '../artifacts.dart';
import '../process.dart';

final Logger _logging = new Logger('sky_tools.run_mojo');

enum _MojoConfig { Debug, Release }

class RunMojoCommand extends Command {
  final String name = 'run_mojo';
  final String description = 'Run a Flutter app in mojo.';

  RunMojoCommand() {
    argParser.addFlag('android', negatable: false, help: 'Run on an Android device');
    argParser.addFlag('checked', negatable: false, help: 'Run Flutter in checked mode');
    argParser.addFlag('mojo-debug', negatable: false, help: 'Use Debug build of mojo');
    argParser.addFlag('mojo-release', negatable: false, help: 'Use Release build of mojo (default)');

    argParser.addOption('app', defaultsTo: 'app.flx');
    argParser.addOption('mojo-path', help: 'Path to directory containing mojo_shell and services');
  }

  // TODO(abarth): Why not use path.absolute?
  Future<String> _makePathAbsolute(String relativePath) async {
    File file = new File(relativePath);
    if (!await file.exists()) {
      throw new Exception("Path \"${relativePath}\" does not exist");
    }
    return file.absolute.path;
  }

  Future<int> _runAndroid(String mojoPath, _MojoConfig mojoConfig, String appPath, List<String> additionalArgs) async {
    String skyViewerUrl = ArtifactStore.googleStorageUrl('viewer', 'android-arm');
    String command = await _makePathAbsolute(path.join(mojoPath, 'mojo', 'devtools', 'common', 'mojo_run'));
    String appName = path.basename(appPath);
    String appDir = path.dirname(appPath);
    String buildFlag = mojoConfig == _MojoConfig.Debug ? '--debug' : '--release';
    List<String> cmd = [
      command,
      '--android',
      buildFlag,
      'http://app/$appName',
      '--map-origin=http://app/=$appDir',
      '--map-origin=http://sky_viewer/=$skyViewerUrl',
      '--url-mappings=mojo:sky_viewer=http://sky_viewer/sky_viewer.mojo',
    ];
    if (_logging.level <= Level.INFO) {
      cmd.add('--verbose');
      if (_logging.level <= Level.FINE) {
        cmd.add('--verbose');
      }
    }
    cmd.addAll(additionalArgs);
    return runCommandAndStreamOutput(cmd);
  }

  Future<int> _runLinux(String mojoPath, _MojoConfig mojoConfig, String appPath, List<String> additionalArgs) async {
    String viewerPath = await _makePathAbsolute(await ArtifactStore.getPath(Artifact.skyViewerMojo));
    String mojoBuildType = mojoConfig == _MojoConfig.Debug ? 'Debug' : 'Release';
    String mojoShellPath = await _makePathAbsolute(path.join(mojoPath, 'out', mojoBuildType, 'mojo_shell'));
    List<String> cmd = [
      mojoShellPath,
      'file://${appPath}',
      '--url-mappings=mojo:sky_viewer=file://${viewerPath}'
    ];
    cmd.addAll(additionalArgs);
    return runCommandAndStreamOutput(cmd);
  }

  @override
  Future<int> run() async {
    if (argResults['mojo-path'] == null) {
      _logging.severe('Must specify --mojo-path to mojo_run');
      return 1;
    }
    if (argResults['mojo-debug'] && argResults['mojo-release']) {
      _logging.severe('Cannot specify both --mojo-debug and --mojo-release');
      return 1;
    }
    List<String> args = [];
    if (argResults['checked']) {
      args.add('--args-for=mojo:sky_viewer --enable-checked-mode');
    }
    String mojoPath = argResults['mojo-path'];
    _MojoConfig mojoConfig = argResults['mojo-debug'] ? _MojoConfig.Debug : _MojoConfig.Release;
    String appPath = await _makePathAbsolute(argResults['app']);

    args.addAll(argResults.rest);
    if (argResults['android']) {
      return _runAndroid(mojoPath, mojoConfig, appPath, args);
    } else {
      return _runLinux(mojoPath, mojoConfig, appPath, args);
    }
  }
}
