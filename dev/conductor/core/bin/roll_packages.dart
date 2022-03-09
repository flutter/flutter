// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:args/command_runner.dart';
import 'package:conductor_core/conductor_core.dart';
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
    parentDirectory: _localFlutterRoot.parent,
    platform: platform,
    processManager: processManager,
    stdio: stdio,
  );

  await RollPackagesContext.fromCommandLine(
    checkouts: checkouts,
    flutterRoot: _localFlutterRoot,
    args: args,
  ).run();
}

Directory get _localFlutterRoot {
  String filePath;
  const FileSystem fileSystem = LocalFileSystem();
  const Platform platform = LocalPlatform();

  filePath = platform.script.toFilePath();
  final String checkoutsDirname = fileSystem.path.normalize(
    fileSystem.path.join(
      fileSystem.path.dirname(filePath), // flutter/dev/conductor/core/bin
      '..', // flutter/dev/conductor/core
      '..', // flutter/dev/conductor
      '..', // flutter/dev
      '..', // flutter
    ),
  );
  return fileSystem.directory(checkoutsDirname);
}
