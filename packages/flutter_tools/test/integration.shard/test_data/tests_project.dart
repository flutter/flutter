// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';

import '../test_utils.dart';
import 'project.dart';

class TestsProject extends Project {
  @override
  final String pubspec = '''
  name: test
  environment:
    sdk: '>=3.2.0-0 <4.0.0'

  dependencies:
    flutter:
      sdk: flutter

  dev_dependencies:
    flutter_test:
      sdk: flutter
  ''';

  @override
  String get main => '// Unused';

  final String testContent = r'''
  import 'package:flutter_test/flutter_test.dart';

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

  String get testFilePath => fileSystem.path.join(dir.path, 'test', 'test.dart');

  Uri get breakpointUri => Uri.file(testFilePath);
  Uri get breakpointAppUri => Uri.parse('org-dartlang-app:///test.dart');

  int get breakpointLine => lineContaining(testContent, '// BREAKPOINT');
}
