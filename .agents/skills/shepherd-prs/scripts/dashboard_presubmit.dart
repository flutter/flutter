// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show Platform, exit, stderr, stdout;

import 'package:file/local.dart';
import 'package:http/http.dart' as http;
import 'package:process/process.dart';

import 'src/cli_runner.dart';
import 'src/models.dart';

Future<void> main(List<String> args) async {
  final client = http.Client();
  try {
    final runner = DashboardCliRunner(
      errSink: stderr,
      fileSystem: const LocalFileSystem(),
      hostEnvironment: HostEnvironment(
        environment: Platform.environment,
        isWindows: Platform.isWindows,
      ),
      httpClient: client,
      outSink: stdout,
      processManager: const LocalProcessManager(),
    );
    final int exitCode = await runner.run(args);
    exit(exitCode);
  } finally {
    client.close();
  }
}
