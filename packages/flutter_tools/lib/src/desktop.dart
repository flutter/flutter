// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'base/io.dart';
import 'base/platform.dart';
import 'base/process_manager.dart';
import 'convert.dart';
import 'device.dart';
import 'version.dart';

// Only launch or display desktop embedding devices if
// `ENABLE_FLUTTER_DESKTOP` environment variable is set to true.
bool get flutterDesktopEnabled {
  _flutterDesktopEnabled ??= platform.environment['ENABLE_FLUTTER_DESKTOP']?.toLowerCase() == 'true';
  return _flutterDesktopEnabled && !FlutterVersion.instance.isStable;
}
bool _flutterDesktopEnabled;

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
  final StreamController<String> _inputController = StreamController<String>.broadcast();

  void initializeProcess(Process process) {
    _inputController.addStream(process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter()));
  }

  @override
  Stream<String> get logLines {
    return _inputController.stream;
  }

  @override
  String get name => 'desktop';
}
