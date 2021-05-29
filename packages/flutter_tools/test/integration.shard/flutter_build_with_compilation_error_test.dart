// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {
  Directory tempDir;
  Directory projectRoot;
  String flutterBin;
  final List<String> targetPlatforms = <String>[
    'apk',
    'web',
    if (platform.isWindows)
      'windows',
    if (platform.isMacOS)
      ...<String>['macos', 'ios'],
  ];

  setUpAll(() {
    tempDir = createResolvedTempDirectorySync('build_compilation_error_test.');
    flutterBin = fileSystem.path.join(
      getFlutterRoot(),
      'bin',
      'flutter',
    );
    processManager.runSync(<String>[flutterBin, 'config',
      '--enable-macos-desktop',
      '--enable-windows-desktop',
      '--enable-web',
    ]);

    processManager.runSync(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'create',
      'hello',
    ], workingDirectory: tempDir.path);

    projectRoot = tempDir.childDirectory('hello');
    writeFile(fileSystem.path.join(projectRoot.path, 'lib', 'main.dart'), '''
int x = 'String';
''');
  });

  tearDownAll(() {
    tryToDelete(tempDir);
  });

  for (final String targetPlatform in targetPlatforms) {
    testWithoutContext('flutter build $targetPlatform shows dart compilation error in non-verbose', () {
      final ProcessResult result = processManager.runSync(<String>[
        flutterBin,
        ...getLocalEngineArguments(),
        'build',
        targetPlatform,
        '--no-pub',
        if (targetPlatform == 'ios')
          '--no-codesign',
      ], workingDirectory: projectRoot.path);

      expect(
        // iOS shows this as stdout.
        targetPlatform == 'ios' ? result.stdout : result.stderr,
        contains("A value of type 'String' can't be assigned to a variable of type 'int'."),
      );
      expect(result.exitCode, 1);
    },
    timeout: const Timeout(Duration(minutes: 3)),
    // framework vms no longer have Visual Studio
    skip: platform.isWindows);
  }
}
