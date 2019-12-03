// Copyright 2014 The Flutter Authors. All rights reserved.
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
  test('analyze.dart - verifyDeprecations', () async {
    final String result = await capture(() => verifyDeprecations(path.join('test', 'analyze-test-input', 'root')), exitCode: 1);
    expect(result,
      '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
      +
      (
        'test/analyze-test-input/root/packages/foo/deprecation.dart:12: Deprecation notice does not match required pattern.\n'
        'test/analyze-test-input/root/packages/foo/deprecation.dart:18: Deprecation notice should be a grammatically correct sentence and start with a capital letter; see style guide.\n'
        'test/analyze-test-input/root/packages/foo/deprecation.dart:25: Deprecation notice should be a grammatically correct sentence and end with a period.\n'
        'test/analyze-test-input/root/packages/foo/deprecation.dart:29: Deprecation notice does not match required pattern.\n'
        'test/analyze-test-input/root/packages/foo/deprecation.dart:32: Deprecation notice does not match required pattern.\n'
        'test/analyze-test-input/root/packages/foo/deprecation.dart:37: Deprecation notice does not match required pattern.\n'
        'test/analyze-test-input/root/packages/foo/deprecation.dart:41: Deprecation notice does not match required pattern.\n'
        'test/analyze-test-input/root/packages/foo/deprecation.dart:48: End of deprecation notice does not match required pattern.\n'
        'test/analyze-test-input/root/packages/foo/deprecation.dart:51: Unexpected deprecation notice indent.\n'
        .replaceAll('/', Platform.isWindows ? '\\' : '/')
      )
      +
      'See: https://github.com/flutter/flutter/wiki/Tree-hygiene#handling-breaking-changes\n'
      '\n'
      '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
      '\n'
    );
  });

  test('analyze.dart - verifyNoMissingLicense', () async {
    final String result = await capture(() => verifyNoMissingLicense(path.join('test', 'analyze-test-input', 'root')), exitCode: 1);
    expect(result,
      '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
      +
      (
        'The following 1 file does not have the right license header:\n'
        '\n'
        'test/analyze-test-input/root/packages/foo/foo.dart\n'
        .replaceAll('/', Platform.isWindows ? '\\' : '/')
      )
      +
      '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
      '\n'
      'The expected license header is:\n'
      '// Copyright 2014 The Flutter Authors. All rights reserved.\n'
      '// Use of this source code is governed by a BSD-style license that can be\n'
      '// found in the LICENSE file.\n'
      '...followed by a blank line.\n'
    );
  });
}
