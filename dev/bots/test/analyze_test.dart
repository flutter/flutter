// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;

import '../analyze.dart';
import 'common.dart';

typedef AsyncVoidCallback = Future<void> Function();

Future<String> capture(AsyncVoidCallback callback, { int exitCode = 0 }) async {
  final StringBuffer buffer = StringBuffer();
  final PrintCallback oldPrint = print;
  try {
    print = (Object line) {
      buffer.writeln(line);
    };
    try {
      await callback();
      expect(exitCode, 0);
    } on ExitException catch (error) {
      expect(error.exitCode, exitCode);
    }
  } finally {
    print = oldPrint;
  }
  return buffer.toString();
}

void main() {
  test('analyze.dart - verifyNoMissingLicense', () async {
    final String result = await capture(() => verifyNoMissingLicense(path.join('test', 'analyze-test-input')), exitCode: 1);
    expect(result, '''
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
License headers cannot be found at the beginning of the following file.

test/analyze-test-input/packages/foo/foo.dart
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

'''.replaceAll('/', Platform.isWindows ? '\\' : '/'));
  });
}
