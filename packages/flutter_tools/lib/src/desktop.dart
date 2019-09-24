// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'base/io.dart';
import 'base/process_manager.dart';
import 'convert.dart';
import 'device.dart';

/// Kills a process on linux or macOS.
Future<bool> killProcess(String executable) async {
  if (executable == null) {
    return false;
  }
  final RegExp whitespace = RegExp(r'\s+');
  bool succeeded = true;
  try {
    final ProcessResult result = await processManager.run(<String>[
      'ps', 'aux',
    ]);
    if (result.exitCode != 0) {
      return false;
    }
    final List<String> lines = result.stdout.split('\n');
    for (String line in lines) {
      if (!line.contains(executable)) {
        continue;
      }
      final List<String> values = line.split(whitespace);
      if (values.length < 2) {
        continue;
      }
      final String processPid = values[1];
      final String currentRunningProcessPid = pid.toString();
      // Don't kill the flutter tool process
      if (processPid == currentRunningProcessPid) {
        continue;
      }

      final ProcessResult killResult = await processManager.run(<String>[
        'kill', processPid,
      ]);
      succeeded &= killResult.exitCode == 0;
    }
    return true;
  } on ArgumentError {
    succeeded = false;
  }
  return succeeded;
}

class DesktopLogReader extends DeviceLogReader {
  final StreamController<List<int>> _inputController = StreamController<List<int>>.broadcast();

  void initializeProcess(Process process) {
    process.stdout.listen(_inputController.add);
    process.stderr.listen(_inputController.add);
    process.exitCode.then((int result) {
      _inputController.close();
    });
  }

  @override
  Stream<String> get logLines {
    return _inputController.stream
      .transform(utf8.decoder)
      .transform(const LineSplitter());
  }

  @override
  String get name => 'desktop';
}
