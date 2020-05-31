// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/args.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../cache.dart';
import '../globals.dart' as globals;
import '../runner/flutter_command.dart';

class UpdatePackagesCommand extends FlutterCommand {
  UpdatePackagesCommand();

  @override
  final ArgParser argParser = ArgParser.allowAnything();

  @override
  final String name = 'update-packages';

  @override
  final String description = 'Update the packages inside the Flutter repo.';

  @override
  final List<String> aliases = <String>['upgrade-packages'];

  @override
  final bool hidden = true;

  @override
  Future<FlutterCommandResult> runCommand() async {
    await globals.processManager.run(
      <String>[
        'dart',
        'pub',
        'get'
      ],
      workingDirectory: globals.fs.path.join(Cache.flutterRoot, 'dev', 'tools')
    );
    final Process process = await globals.processManager.start(
      <String>[
        'dart',
        '--disable-dart-dev',
        'lib/repo_tools.dart',
        'update-packages',
        ...argResults.arguments,
      ],
      workingDirectory: globals.fs.path.join(Cache.flutterRoot, 'dev', 'tools'),
      mode: ProcessStartMode.inheritStdio,
    );
    await process.exitCode;
    return FlutterCommandResult.success();
  }
}
