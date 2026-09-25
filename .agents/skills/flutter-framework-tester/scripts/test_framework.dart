// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

void main(List<String> args) async {
  final String scriptPath = Platform.script.toFilePath();
  final Directory scriptDir = File(scriptPath).parent;
  final Directory repoRootDir = scriptDir.parent.parent.parent.parent;

  if (args.isEmpty) {
    stderr.writeln('Error: No test target specified. Example: packages/flutter/test/foundation');
    exit(1);
  }

  var useLocalEngine = false;
  final targets = <String>[];
  for (final arg in args) {
    if (arg == '--local-engine') {
      useLocalEngine = true;
    } else {
      targets.add(arg);
    }
  }

  if (targets.isEmpty) {
    stderr.writeln('Error: No test target specified.');
    exit(1);
  }

  final flutterArgs = <String>['test', '--no-pub'];
  if (useLocalEngine) {
    flutterArgs.add('--local-engine=host_debug_unopt');
    flutterArgs.add('--local-engine-host=host_debug_unopt');
  }
  flutterArgs.addAll(targets);

  final flutterPath = '${repoRootDir.path}/bin/flutter';
  if (!File(flutterPath).existsSync()) {
    stderr.writeln('Error: flutter binary not found at $flutterPath');
    exit(1);
  }

  stdout.writeln('Running framework tests using flutter ${flutterArgs.join(' ')}...');
  final Process process = await Process.start(
    flutterPath,
    flutterArgs,
    workingDirectory: repoRootDir.path,
    environment: <String, String>{
      'http_proxy': '',
      'https_proxy': '',
      'HTTP_PROXY': '',
      'HTTPS_PROXY': '',
    },
    mode: ProcessStartMode.inheritStdio,
  );
  exit(await process.exitCode);
}
