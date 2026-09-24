// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:engine_repo_tools/engine_repo_tools.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  test('create_updated_flutter_deps_tests.py passes and verifies dart2wasm support parity', () {
    final io.Directory srcDir = Engine.findWithin().srcDir;
    final String testScript = path.join(
      srcDir.path,
      'tools',
      'dart',
      'create_updated_flutter_deps_tests.py',
    );
    final io.ProcessResult result = io.Process.runSync('python3', <String>[
      testScript,
    ], workingDirectory: srcDir.parent.path);
    expect(result.exitCode, 0, reason: 'stdout:\n${result.stdout}\nstderr:\n${result.stderr}');
  });
}
