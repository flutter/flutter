// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:yaml_edit/yaml_edit.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = createResolvedTempDirectorySync('ios_app_with_extensions_test.');
  });

  tearDown(() {
    tryToDelete(tempDir);
  });

  test(
    'flutter build ios attempts to build the companion watchOS app',
    () async {
      final String flutterRoot = getFlutterRoot();

      // Build a copy so the tool's project migrations don't dirty the checked-in project.
      final Directory workspaceRoot = tempDir.childDirectory('app_workspace');
      final Directory projectDir = workspaceRoot.childDirectory('app_with_extensions');
      copyDirectory(
        fileSystem.directory(
          fileSystem.path.join(flutterRoot, 'dev', 'integration_tests', 'ios_app_with_extensions'),
        ),
        projectDir,
      );
      final yamlEditor = YamlEditor(
        fileSystem.file(fileSystem.path.join(flutterRoot, 'pubspec.yaml')).readAsStringSync(),
      );
      yamlEditor.update(<String>['workspace'], <String>['app_with_extensions']);
      workspaceRoot.childFile('pubspec.yaml').writeAsStringSync(yamlEditor.toString());

      // The watchOS SDK is not available in CI, so the watch target itself
      // cannot be built. Verify the tool at least queries the watch build
      // settings. See https://github.com/flutter/flutter/pull/94190.
      final ProcessResult result = await processManager.run(<String>[
        flutterBin,
        ...getLocalEngineArguments(),
        'build',
        'ios',
        '--no-codesign',
        '--release',
        '--verbose',
      ], workingDirectory: projectDir.path);

      expect(
        result,
        const ProcessResultMatcher(stdoutPattern: '-destination generic/platform=watchOS'),
      );
    },
    skip: !platform.isMacOS, // [intended] only makes sense for macos platform.
  );
}
