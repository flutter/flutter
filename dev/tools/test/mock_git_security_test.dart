// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ----------------------------------------------------------------------
// SECURITY NOTE
// ----------------------------------------------------------------------
// This test verifies metacharacters in argv are printed as data and are not
// executed as shell syntax.
// ----------------------------------------------------------------------

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  final String repoRoot = path.normalize(Directory.current.path);
  final String scriptPath = path.join(repoRoot, 'dev', 'tools', 'test', 'mock_git.sh');

  test('mock_git.sh does not execute injected shell payload from argv', () async {
    final ProcessResult result = await Process.run('bash', <String>[
      scriptPath,
      'status; echo HACKED',
    ]);

    expect(result.exitCode, 0);
    expect(result.stdout, 'Mock Git: status; echo HACKED\n');
    expect((result.stdout as String).trim(), isNot(equals('HACKED')));
  });
}
