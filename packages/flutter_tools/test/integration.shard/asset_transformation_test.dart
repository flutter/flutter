// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';

import '../src/common.dart';
import 'test_utils.dart';

Future<void> main() async {
  testWithoutContext('asset is transformed when declared with a transformation', () async {
    final Directory tempDir = createResolvedTempDirectorySync(
      'asset_transformation_test.',
    );

    try {
      final String projectDir = fileSystem.path.join(
        getFlutterRoot(),
        'dev',
        'integration_tests',
        'asset_transformation',
      );

      copyDirectory(fileSystem.directory(projectDir), tempDir);
      final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');
      await processManager.run(<String>[
        flutterBin,
        'build',
        'web',
      ], workingDirectory: tempDir.path);

      final File asset = fileSystem.file(
        fileSystem.path.join(
          tempDir.path,
          'build',
          'web',
          'assets',
          'assets',
          'test_asset.txt',
        ),
      );

      expect(asset, exists);

      expect(
        asset.readAsStringSync(),
        equals('ABC'),
        reason:
          "The original contents of the asset (which should be 'abc') should "
          "have been transformed to 'ABC' by the capitalizer_transformer as "
          'configured in the pubspec.',
      );
    } finally {
      tryToDelete(tempDir);
    }
  });
}
