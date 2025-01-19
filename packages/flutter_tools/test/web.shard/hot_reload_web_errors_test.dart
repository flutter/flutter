// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@Tags(<String>['flutter-test-driver'])
library;

import 'package:file/file.dart';

import '../integration.shard/test_data/hot_reload_const_project.dart';
import '../integration.shard/test_driver.dart';
import '../integration.shard/test_utils.dart';
import '../src/common.dart';

void main() {
  late Directory tempDir;
  final HotReloadConstProject project = HotReloadConstProject();
  late FlutterRunTestDriver flutter;

  final List<String> additionalCommandArgs = <String>[
    '--extra-front-end-options=--dartdevc-canary,--dartdevc-module-format=ddc',
  ];

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('hot_reload_test.');
    await project.setUpIn(tempDir);
    flutter = FlutterRunTestDriver(tempDir);
  });

  tearDown(() async {
    await flutter.stop();
    tryToDelete(tempDir);
  });

  testWithoutContext(
    'hot reload displays an error message when removing a field from a const class',
    () async {
      await flutter.run(chrome: true, additionalCommandArgs: additionalCommandArgs);
      project.removeFieldFromConstClass();

      expect(
        flutter.hotReload(),
        throwsA(
          isA<Exception>().having(
            (Exception e) => e.toString(),
            'message',
            // TODO(srujzs): Change this to "Try performing a hot restart instead." once we emit
            // that string in the delta inspector. Then unify this test with
            // hot_reload_errors_test.dart.
            contains('Const class cannot become non-const'),
          ),
        ),
      );
    },
  );

  testWithoutContext('hot restart succeeds when removing a field from a const class', () async {
    // We should have used `recompile-restart` to avoid the errors the DDC delta
    // inspector emits.
    await flutter.run(chrome: true, additionalCommandArgs: additionalCommandArgs);
    project.removeFieldFromConstClass();
    await flutter.hotRestart();
  });
}
