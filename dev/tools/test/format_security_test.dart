// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ----------------------------------------------------------------------
// SECURITY NOTE
// ----------------------------------------------------------------------
// This test verifies that format.sh properly rejects malicious environment
// variables that could be used for command injection attacks. See Flutter
// security guidelines for CI tooling.
// ----------------------------------------------------------------------

import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  final repoRoot = path.dirname(path.dirname(path.dirname(path.dirname(
      path.dirname(Platform.script.toFilePath())))));

  test('format.sh aborts when DART env var contains shell injection', () async {
    final result = await Process.run(
      'bash',
      ['${repoRoot}/dev/tools/format.sh'],
      environment: {'DART': '; echo HACKED'},
    );
    // Script should fail because the malformed DART variable breaks the command.
    expect(result.exitCode, isNot(0));
    // The injected payload must not appear in stdout or stderr.
    expect(result.stdout, isNot(contains('HACKED')));
    expect(result.stderr, isNot(contains('HACKED')));
  });
}