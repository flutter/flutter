// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:test/test.dart';
import 'package:flutter_tools/src/debug_adapters/flutter_adapter_args.dart';

void main() {
  test('rejects non-absolute customTool', () {
    expect(() => FlutterLaunchRequestArguments(customTool: 'bin/flutter', program: null), throwsFormatException);
  });

  test('rejects disallowed basename even if absolute', () {
    final path = Platform.isWindows ? r'C:\Windows\System32\cmd.exe' : '/bin/sh';
    expect(() => FlutterLaunchRequestArguments(customTool: path, program: null), throwsFormatException);
  });

  test('accepts allowed basename when file exists and is executable', () async {
    if (Platform.isWindows) {
      // On Windows, skip executable permission checks and just ensure basename check.
      // Create a temp file named flutter to satisfy the basename allowlist.
      final tmpDir = await Directory.systemTemp.createTemp('flutter_adapter_test');
      final file = File('${tmpDir.path}${Platform.pathSeparator}flutter');
      await file.writeAsString('echo');
      try {
        // Should throw only if path is not absolute; this is absolute.
        FlutterLaunchRequestArguments(customTool: file.path, program: null);
      } finally {
        await tmpDir.delete(recursive: true);
      }
    } else {
      final tmpDir = await Directory.systemTemp.createTemp('flutter_adapter_test');
      final file = File('${tmpDir.path}${Platform.pathSeparator}flutter');
      await file.writeAsString('echo');
      // Make it executable.
      await Process.run('chmod', ['+x', file.path]);
      try {
        FlutterLaunchRequestArguments(customTool: file.path, program: null);
      } finally {
        await tmpDir.delete(recursive: true);
      }
    }
  });
}
