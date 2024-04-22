// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:path/path.dart' as path;

import '../utils.dart';

Future<void> toolTestsRunner() async {
  final String toolsPath = path.join(flutterRoot, 'packages', 'flutter_tools');

  await selectSubshard(<String, ShardRunner>{
    'general': () => _runGeneralToolTests(toolsPath),
    'commands': () =>  _runCommandsToolTests(toolsPath),
  });
}

Future<void> _runGeneralToolTests(String toolsPath) async {
  await runDartTest(
    toolsPath,
    testPaths: <String>[path.join('test', 'general.shard')],
    enableFlutterToolAsserts: false,

    // Detect unit test time regressions (poor time delay handling, etc).
    // This overrides the 15 minute default for tools tests.
    // See the README.md and dart_test.yaml files in the flutter_tools package.
    perTestTimeout: const Duration(seconds: 2),
  );
}

Future<void> _runCommandsToolTests(String toolsPath) async {
  await runDartTest(
    toolsPath,
    forceSingleCore: true,
    testPaths: <String>[path.join('test', 'commands.shard')],
  );
}
