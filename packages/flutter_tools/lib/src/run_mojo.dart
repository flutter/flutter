// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library sky_tools.run_mojo;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

import 'artifacts.dart';
import 'common.dart';

final Logger _logging = new Logger('sky_tools.run_mojo');

class RunMojoCommandHandler extends CommandHandler {
  RunMojoCommandHandler() : super('run_mojo', 'Run a Flutter app in mojo.');

  ArgParser get parser {
    ArgParser parser = new ArgParser();
    parser.addFlag('help', abbr: 'h', negatable: false);
    parser.addOption('package-root', defaultsTo: 'packages');
    parser.addOption('mojo-path', help: 'Path to directory containing mojo_shell and services');
    parser.addOption('app', defaultsTo: 'app.flx');
    return parser;
  }

  Future<String> _makePathAbsolute(String relativePath) async {
    File file = new File(relativePath);
    if (!await file.exists()) {
      throw new Exception("Path \"${relativePath}\" does not exist");
    }
    return file.absolute.path;
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
    String appPath = await _makePathAbsolute(results['app']);
    String viewerPath = await _makePathAbsolute(await artifactStore.getPath(Artifact.SkyViewerMojo, packageRoot));
    String mojoShellPath = await _makePathAbsolute(path.join(results['mojo-path'], 'mojo_shell'));
    List<String> mojoRunArgs = [
      'mojo:window_manager file://${appPath}',
      '--url-mappings=mojo:window_manager=mojo:kiosk_wm,mojo:sky_viewer=file://${viewerPath}'
    ];
    _logging.fine("Starting ${mojoShellPath} with args: ${mojoRunArgs}");
    Process proc = await Process.start(mojoShellPath, mojoRunArgs);
    proc.stdout.transform(UTF8.decoder).listen((data) {
      stdout.write(data);
    });
    proc.stderr.transform(UTF8.decoder).listen((data) {
      stderr.write(data);
    });
    int exitCode = await proc.exitCode;
    if (exitCode != 0) throw new Exception(exitCode);
    return 0;
  }
}
