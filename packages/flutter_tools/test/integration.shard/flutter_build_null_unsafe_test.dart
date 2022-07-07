// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {
  late Directory tempDir;
  late Directory projectRoot;
  late String flutterBin;
  final List<String> targetPlatforms = <String>[
    'apk',
    'web',
    if (platform.isWindows) 'windows',
    if (platform.isMacOS) ...<String>['macos', 'ios'],
  ];

  setUpAll(() {
    tempDir = createResolvedTempDirectorySync('build_null_unsafe_test.');
    flutterBin = fileSystem.path.join(
      getFlutterRoot(),
      'bin',
      'flutter',
    );
    processManager.runSync(<String>[
      flutterBin,
      'config',
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
    writeFile(fileSystem.path.join(projectRoot.path, 'pubspec.yaml'), '''
name: hello
environment:
  sdk: '>=2.12.0 <3.0.0'
''');
    writeFile(fileSystem.path.join(projectRoot.path, 'lib', 'main.dart'), '''
import 'unsafe.dart';
void main() {
  print(unsafeString);
}
''');
    writeFile(fileSystem.path.join(projectRoot.path, 'lib', 'unsafe.dart'), '''
// @dart=2.9
String unsafeString = null;
''');
  });

  tearDownAll(() {
    tryToDelete(tempDir);
  });

  for (final String targetPlatform in targetPlatforms) {
    testWithoutContext('flutter build $targetPlatform --no-sound-null-safety', () {
      final ProcessResult result = processManager.runSync(<String>[
        flutterBin,
        ...getLocalEngineArguments(),
        'build',
        targetPlatform,
        '--no-pub',
        '--no-sound-null-safety',
        if (targetPlatform == 'ios') '--no-codesign',
      ], workingDirectory: projectRoot.path);

      if (result.exitCode != 0) {
        fail('build --no-sound-null-safety failed: ${result.exitCode}\n${result.stderr}\n${result.stdout}');
      }
    });
  }
}
