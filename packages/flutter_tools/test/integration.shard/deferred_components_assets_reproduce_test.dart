// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@Timeout(Duration(minutes: 5))
@Tags(<String>['flutter-test-driver'])
library;

import 'package:archive/archive.dart';
import 'package:file/file.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_data/deferred_components_project.dart';
import 'test_utils.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = createResolvedTempDirectorySync('deferred_components_assets_reproduce.');
  });

  tearDown(() {
    tryToDelete(tempDir);
  });

  testWithoutContext(
    'deferred components assets are not missing on clean build',
    () async {
      final project = DeferredComponentsProject(BasicDeferredComponentsConfig());
      await project.setUpIn(tempDir);

      final ProcessResult result = await processManager.run(<String>[
        flutterBin,
        ...getLocalEngineArguments(),
        'build',
        'appbundle',
        '--target-platform=android-arm64',
        '--no-validate-deferred-components',
      ], workingDirectory: tempDir.path);

      expect(result.stdout.toString(), contains('app-release.aab'));

      final String line = result.stdout
          .toString()
          .split('\n')
          .firstWhere((String line) => line.contains('app-release.aab'));

      final String outputFilePath = line.split(' ')[2].trim();
      final File outputFile = fileSystem.file(fileSystem.path.join(tempDir.path, outputFilePath));
      expect(outputFile, exists);

      final Archive archive = ZipDecoder().decodeBytes(outputFile.readAsBytesSync());

      // Verification: asset2.txt inside component1 should be present.
      expect(
        archive.findFile('component1/assets/flutter_assets/test_assets/asset2.txt') != null,
        true,
      );
    },
  );
}
