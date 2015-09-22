// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library sky_tools.run_mojo;

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

import 'artifacts.dart';
import 'common.dart';
import 'process.dart';

final Logger _logging = new Logger('sky_tools.run_mojo');

class RunMojoCommandHandler extends CommandHandler {
  RunMojoCommandHandler() : super('run_mojo', 'Run a Flutter app in mojo.');

  ArgParser get parser {
    ArgParser parser = new ArgParser();
    parser.addFlag('android', negatable: false, help: 'Run on an Android device');
    parser.addFlag('help', abbr: 'h', negatable: false);
    parser.addOption('app', defaultsTo: 'app.flx');
    parser.addOption('mojo-path', help: 'Path to directory containing mojo_shell and services');
    parser.addOption('package-root', defaultsTo: 'packages');
    return parser;
  }

  Future<String> _makePathAbsolute(String relativePath) async {
    File file = new File(relativePath);
    if (!await file.exists()) {
      throw new Exception("Path \"${relativePath}\" does not exist");
    }
    return file.absolute.path;
  }

  Future<int> _runAndroid(ArgResults results, String appPath, ArtifactStore artifacts) async {
    String skyViewerUrl = artifacts.googleStorageUrl('viewer', 'android-arm');
    String command = await _makePathAbsolute(path.join(results['mojo-path'], 'mojo', 'devtools', 'common', 'mojo_run'));
    String appName = path.basename(appPath);
    String appDir = path.dirname(appPath);
    List<String> args = [
      '--android', '--release', '--embed', 'http://app/$appName',
      '--map-origin=http://app/=$appDir',
      '--map-origin=http://sky_viewer/=$skyViewerUrl',
      '--url-mappings=mojo:sky_viewer=http://sky_viewer/sky_viewer.mojo',
    ];
    if (_logging.level <= Level.INFO) {
      args.add('--verbose');
      if (_logging.level <= Level.FINE) {
        args.add('--verbose');
      }
    }
    return runCommandAndStreamOutput(command, args);
  }

  Future<int> _runLinux(ArgResults results, String appPath, ArtifactStore artifacts) async {
    String viewerPath = await _makePathAbsolute(await artifacts.getPath(Artifact.SkyViewerMojo));
    String mojoShellPath = await _makePathAbsolute(path.join(results['mojo-path'], 'out', 'Release', 'mojo_shell'));
    List<String> mojoRunArgs = [
      'mojo:window_manager file://${appPath}',
      '--url-mappings=mojo:window_manager=mojo:kiosk_wm,mojo:sky_viewer=file://${viewerPath}'
    ];
    return runCommandAndStreamOutput(mojoShellPath, mojoRunArgs);
  }

  @override
  Future<int> processArgResults(ArgResults results) async {
    if (results['help']) {
      print(parser.usage);
      return 0;
    }
    if (results['mojo-path'] == null) {
      _logging.severe('Must specify --mojo-path to mojo_run');
      return 1;
    }
    String packageRoot = results['package-root'];
    ArtifactStore artifacts = new ArtifactStore(packageRoot);
    String appPath = await _makePathAbsolute(results['app']);
    if (results['android']) {
      return _runAndroid(results, appPath, artifacts);
    } else {
      return _runLinux(results, appPath, artifacts);
    }
  }
}
