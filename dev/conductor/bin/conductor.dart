// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// See: https://github.com/flutter/flutter/wiki/Release-process

import 'dart:io' as io;

import 'package:args/command_runner.dart';
import 'package:conductor/candidates.dart';
import 'package:conductor/clean.dart';
import 'package:conductor/codesign.dart';
import 'package:conductor/globals.dart';
import 'package:conductor/next.dart';
import 'package:conductor/repository.dart';
import 'package:conductor/roll_dev.dart';
import 'package:conductor/start.dart';
import 'package:conductor/status.dart';
import 'package:conductor/stdio.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

const String readmeUrl = 'https://github.com/flutter/flutter/tree/master/dev/conductor/README.md';

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
    'A tool for coordinating Flutter releases. For more documentation on '
    'usage, please see $readmeUrl.',
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
    StatusCommand(
      checkouts: checkouts,
    ),
    StartCommand(
      checkouts: checkouts,
      flutterRoot: localFlutterRoot,
    ),
    CleanCommand(
      checkouts: checkouts,
    ),
    CandidatesCommand(
      checkouts: checkouts,
      flutterRoot: localFlutterRoot,
    ),
    NextCommand(
      checkouts: checkouts,
    ),
  ].forEach(runner.addCommand);

  if (!assertsEnabled()) {
    stdio.printError('The conductor tool must be run with --enable-asserts.');
    io.exit(1);
  }

  try {
    await runner.run(args);
  } on Exception catch (e, stacktrace) {
    stdio.printError('$e\n\n$stacktrace');
    io.exit(1);
  }
}
