// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'collect.dart';
import 'util.dart';

Future<Map<String, dynamic>> runAndCollect(String scriptPath,
    {List<String>? scriptArgs,
    bool checked = false,
    bool includeDart = false,
    Duration? timeout}) async {
  final dartArgs = [
    '--enable-vm-service',
    '--pause_isolates_on_exit',
    if (checked) '--checked',
    scriptPath,
    ...?scriptArgs,
  ];

  final process = await Process.start(Platform.executable, dartArgs);

  final serviceUri = await serviceUriFromProcess(process.stdout.lines());
  Map<String, dynamic> coverage;
  try {
    coverage = await collect(
      serviceUri,
      true,
      true,
      includeDart,
      <String>{},
      timeout: timeout,
    );
  } finally {
    await process.stderr.drain();
  }
  final exitStatus = await process.exitCode;
  if (exitStatus != 0) {
    throw ProcessException(
      Platform.executable,
      dartArgs,
      'Process failed.',
      exitStatus,
    );
  }
  return coverage;
}
