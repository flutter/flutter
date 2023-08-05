// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';

import '../test_utils.dart';
import 'project.dart';
import 'tests_project.dart';

class IntegrationTestsProject extends Project implements TestsProject {
  @override
  final String pubspec = '''
  name: test
  environment:
    sdk: '>=3.0.0-0 <4.0.0'

  dependencies:
    flutter:
      sdk: flutter

  dev_dependencies:
    integration_test:
      sdk: flutter
    flutter_test:
      sdk: flutter
  ''';

  @override
  String get main => '// Unused';

  @override
  final String testContent = r'''
  import 'package:flutter_test/flutter_test.dart';
  import 'package:integration_test/integration_test.dart';

  void main() {
    group('Flutter tests', () {
      testWidgets('can pass', (WidgetTester tester) async {
        expect(true, isTrue); // BREAKPOINT
      });
      testWidgets('can fail', (WidgetTester tester) async {
        expect(true, isFalse);
      });
    });
  }
  ''';

  @override
  Future<void> setUpIn(Directory dir) {
    this.dir = dir;
    writeFile(testFilePath, testContent);
    return super.setUpIn(dir);
  }

  @override
  String get testFilePath => fileSystem.path.join(dir.path, 'integration_test', 'app_test.dart');

  @override
  Uri get breakpointUri => Uri.file(testFilePath);

  @override
  Uri get breakpointAppUri => throw UnimplementedError();

  @override
  int get breakpointLine => lineContaining(testContent, '// BREAKPOINT');
}
