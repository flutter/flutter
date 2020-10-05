// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file_testing/file_testing.dart';

import '../src/common.dart';

import 'test_data/test_project.dart';
import 'test_driver.dart';
import 'test_utils.dart';

void main() {
  Directory tempDir;

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('flutter_coverage_collection_test.');
  });

  tearDown(() async {
    tryToDelete(tempDir);
  });

  testWithoutContext('Can collect coverage in machine mode', () async {
    final TestProject project = TestProject();
    await project.setUpIn(tempDir);
    final FlutterTestTestDriver flutter = FlutterTestTestDriver(tempDir);
    await flutter.test(coverage: true);
    await flutter.done;

    expect(tempDir.childDirectory('coverage').childFile('lcov.info'), exists);
  });
}
