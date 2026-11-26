// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_utils.dart';

// AppleDouble header magic (0x00051607), version 2 (0x00020000), and invalid UTF-8 bytes.
const _appleDoubleBytes = <int>[
  0x00,
  0x05,
  0x16,
  0x07,
  0x00,
  0x02,
  0x00,
  0x00,
  0xFF,
  0xFE,
  0x80,
  0xC0,
];

// UTF-16 LE BOM (0xFF, 0xFE) followed by UTF-16 LE encoded "void main() {}".
const _utf16LeTestBytes = <int>[
  0xFF,
  0xFE,
  0x76,
  0x00,
  0x6F,
  0x00,
  0x69,
  0x00,
  0x64,
  0x00,
  0x20,
  0x00,
  0x6D,
  0x00,
  0x61,
  0x00,
  0x69,
  0x00,
  0x6E,
  0x00,
  0x28,
  0x00,
  0x29,
  0x00,
  0x20,
  0x00,
  0x7B,
  0x00,
  0x7D,
  0x00,
];

const _pubspecContents = '''
name: test_app
environment:
  sdk: ^3.7.0-0

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
''';

const _passingWidgetTestContents = '''
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('smoke test', (WidgetTester tester) async {
    expect(1 + 1, 2);
  });
}
''';

// Regression tests for https://github.com/flutter/flutter/issues/196120.
void main() {
  late Directory tempRoot;
  late Directory projectDir;

  Future<ProcessResult> runFlutterTool(List<String> args) {
    return processManager.run(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      ...args,
    ], workingDirectory: projectDir.path);
  }

  setUpAll(() async {
    tempRoot = createResolvedTempDirectorySync('test_file_encoding.');
    projectDir = tempRoot.childDirectory('app')..createSync(recursive: true);

    writeFile(fileSystem.path.join(projectDir.path, 'pubspec.yaml'), _pubspecContents);
    final ProcessResult pubGetResult = await runFlutterTool(const <String>['pub', 'get']);
    if (pubGetResult.exitCode != 0) {
      fail('flutter pub get failed:\n${pubGetResult.stdout}\n${pubGetResult.stderr}');
    }
  });

  tearDownAll(() {
    tryToDelete(tempRoot);
  });

  setUp(() {
    final Directory testDir = projectDir.childDirectory('test');
    if (testDir.existsSync()) {
      testDir.deleteSync(recursive: true);
    }
    testDir.createSync(recursive: true);
  });

  test('flutter test ignores binary AppleDouble sidecar files during discovery', () async {
    writeFile(
      fileSystem.path.join(projectDir.path, 'test', 'widget_test.dart'),
      _passingWidgetTestContents,
    );
    writeBytesFile(
      fileSystem.path.join(projectDir.path, 'test', '._a_test.dart'),
      _appleDoubleBytes,
    );
    writeBytesFile(
      fileSystem.path.join(projectDir.path, 'test', '._widget_test.dart'),
      _appleDoubleBytes,
    );

    final ProcessResult result = await runFlutterTool(const <String>['test', '--no-pub']);

    expect(result, const ProcessResultMatcher(stdoutPattern: 'All tests passed!'));
  });

  test(
    'flutter test exits gracefully without crashing when test files are not UTF-8 encoded',
    () async {
      writeFile(
        fileSystem.path.join(projectDir.path, 'test', 'widget_test.dart'),
        _passingWidgetTestContents,
      );
      writeBytesFile(
        fileSystem.path.join(projectDir.path, 'test', 'non_utf8_1_test.dart'),
        _utf16LeTestBytes,
      );
      writeBytesFile(
        fileSystem.path.join(projectDir.path, 'test', 'non_utf8_2_test.dart'),
        _utf16LeTestBytes,
      );

      final ProcessResult result = await runFlutterTool(const <String>['test', '--no-pub']);
      final combinedOutput = '${result.stdout}\n${result.stderr}';

      expect(result.exitCode, 1, reason: combinedOutput);
      expect(combinedOutput, contains('Failed to read test file'));
      expect(
        combinedOutput,
        contains('Ensure that the file is a valid UTF-8 encoded Dart test file.'),
      );
      expect(combinedOutput, isNot(contains('Feature flags enabled:')));
      expect(combinedOutput, isNot(contains('Oops; flutter has exited unexpectedly')));
      expect(combinedOutput, isNot(contains('This is an unexpected error')));
      expect(combinedOutput, isNot(contains('Loader.loadFile')));
    },
  );

  test(
    'flutter test exits gracefully when a binary or AppleDouble file is passed explicitly',
    () async {
      final String appleDoublePath = fileSystem.path.join('test', '._widget_test.dart');
      writeBytesFile(fileSystem.path.join(projectDir.path, appleDoublePath), _appleDoubleBytes);

      final ProcessResult result = await runFlutterTool(<String>[
        'test',
        '--no-pub',
        appleDoublePath,
      ]);
      final combinedOutput = '${result.stdout}\n${result.stderr}';

      expect(result.exitCode, 1, reason: combinedOutput);
      expect(combinedOutput, contains('Failed to read test file'));
      expect(combinedOutput, contains('._widget_test.dart'));
      expect(
        combinedOutput,
        contains('Ensure that the file is a valid UTF-8 encoded Dart test file.'),
      );
      expect(combinedOutput, isNot(contains('This is an unexpected error')));
      expect(combinedOutput, isNot(contains('Loader.loadFile')));
    },
  );
}
