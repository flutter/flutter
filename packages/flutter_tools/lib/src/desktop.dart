// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import 'base/common.dart';
import 'base/io.dart';
import 'base/platform.dart';
import 'base/process_manager.dart';
import 'convert.dart';
import 'device.dart';
import 'version.dart';

@visibleForTesting
bool debugDisableDesktop = false;

/// Only launch or display desktop embedding devices from the command line
/// or if `ENABLE_FLUTTER_DESKTOP` environment variable is set to true.
bool get flutterDesktopEnabled {
  if (debugDisableDesktop) {
    return false;
  }
  if (isRunningFromDaemon) {
    final bool platformEnabled = platform
        .environment['ENABLE_FLUTTER_DESKTOP']?.toLowerCase() == 'true';
    return platformEnabled && FlutterVersion.instance.isMaster;
  }
  return FlutterVersion.instance.isMaster;
}

/// Kills a process on linux or macOS.
Future<bool> killProcess(String executable) async {
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
      final String pid = values[1];
      final ProcessResult killResult = await processManager.run(<String>[
        'kill', pid,
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
