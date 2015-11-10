// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

import '../artifacts.dart';
import '../build_configuration.dart';
import '../process.dart';

final Logger _logging = new Logger('flutter_tools.run_mojo');

class RunMojoCommand extends Command {
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

  // TODO(abarth): Why not use path.absolute?
  String _makePathAbsolute(String relativePath) {
    File file = new File(relativePath);
    if (!file.existsSync()) {
      throw new Exception("Path \"${relativePath}\" does not exist");
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

  Future<List<String>> _getShellConfig() async {
    List<String> args = [];

    final useDevtools = _useDevtools();
    final command = useDevtools ? _getDevtoolsPath() : _getMojoShellPath();
    args.add(command);

    if (argResults['android']) {
      args.add('--android');
      final skyViewerUrl = ArtifactStore.getCloudStorageBaseUrl('viewer', 'android-arm');
      final appPath = _makePathAbsolute(argResults['app']);
      final appName = path.basename(appPath);
      final appDir = path.dirname(appPath);
      args.add('http://app/$appName');
      args.add('--map-origin=http://app/=$appDir');
      args.add('--map-origin=http://sky_viewer/=$skyViewerUrl');
      args.add('--url-mappings=mojo:sky_viewer=http://sky_viewer/sky_viewer.mojo');
    } else {
      final appPath = _makePathAbsolute(argResults['app']);
      Artifact artifact = ArtifactStore.getArtifact(type: ArtifactType.viewer, targetPlatform: TargetPlatform.linux);
      final viewerPath = _makePathAbsolute(await ArtifactStore.getPath(artifact));
      args.add('file://${appPath}');
      args.add('--url-mappings=mojo:sky_viewer=file://${viewerPath}');
    }

    if (useDevtools) {
      final buildFlag = argResults['mojo-debug'] ? '--debug' : '--release';
      args.add(buildFlag);
      if (_logging.level <= Level.INFO) {
        args.add('--verbose');
        if (_logging.level <= Level.FINE) {
          args.add('--verbose');
        }
      }
    }

    if (argResults['checked']) {
      args.add('--args-for=mojo:sky_viewer --enable-checked-mode');
    }

    args.addAll(argResults.rest);
    print(args);
    return args;
  }

  @override
  Future<int> run() async {
    if ((argResults['mojo-path'] == null && argResults['devtools-path'] == null) || (argResults['mojo-path'] != null && argResults['devtools-path'] != null)) {
      _logging.severe('Must specify either --mojo-path or --devtools-path.');
      return 1;
    }

    if (argResults['mojo-debug'] && argResults['mojo-release']) {
      _logging.severe('Cannot specify both --mojo-debug and --mojo-release');
      return 1;
    }

    return runCommandAndStreamOutput(await _getShellConfig());
  }
}
