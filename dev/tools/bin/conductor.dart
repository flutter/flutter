// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Rolls the dev channel.
// Only tested on Linux.
//
// See: https://github.com/flutter/flutter/wiki/Release-process

import 'dart:io' as io;

import 'package:args/command_runner.dart';
import 'package:dev_tools/codesign.dart';
import 'package:dev_tools/globals.dart';
import 'package:dev_tools/roll_dev.dart';
import 'package:dev_tools/repository.dart';
import 'package:dev_tools/stdio.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

Future<void> main(List<String> args) async {
  const FileSystem fileSystem = LocalFileSystem();
  const ProcessManager processManager = LocalProcessManager();
  const Platform platform = LocalPlatform();
  final Stdio stdio = VerboseStdio(
    stdout: io.stdout,
    stderr: io.stderr,
    stdin: io.stdin,
  );
  final Checkouts checkouts = Checkouts(
    fileSystem: fileSystem,
    parentDirectory: localFlutterRoot.parent,
    platform: platform,
    processManager: processManager,
    stdio: stdio,
  );

  final CommandRunner<void> runner = CommandRunner<void>(
    'conductor',
    'A tool for coordinating Flutter releases.',
    usageLineLength: 80,
  );

  <Command<void>>[
    RollDevCommand(
      checkouts: checkouts,
      fileSystem: fileSystem,
      platform: platform,
      stdio: stdio,
    ),
    CodesignCommand(
      checkouts: checkouts,
      flutterRoot: localFlutterRoot,
    ),
  ].forEach(runner.addCommand);

  if (!assertsEnabled()) {
    stdio.printError('The conductor tool must be run with --enable-asserts.');
    io.exit(1);
  }

  try {
    await runner.run(args);
  } on Exception catch (e) {
    stdio.printError(e.toString());
    io.exit(1);
  }
}
