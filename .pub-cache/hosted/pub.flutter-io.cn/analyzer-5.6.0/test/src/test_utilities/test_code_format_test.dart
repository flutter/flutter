// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TestCodeFormatTest);
  });
}

@reflectiveTest
class TestCodeFormatTest {
  void test_noMarkers() {
    final rawCode = '''
int a = 1;
''';
    final code = TestCode.parse(rawCode);
    expect(code.rawCode, rawCode);
    expect(code.code, rawCode); // no difference
    expect(code.positions, isEmpty);
    expect(code.ranges, isEmpty);
  }

  void test_positions() {
    final rawCode = '''
int /*0*/a = 1;/*1*/
int b/*2*/ = 2;
''';
    final expectedCode = '''
int a = 1;
int b = 2;
''';
    final code = TestCode.parse(rawCode);
    expect(code.rawCode, rawCode);
    expect(code.code, expectedCode);
    expect(code.ranges, isEmpty);

    expect(code.positions[0].offset, 4);
    expect(code.positions[1].offset, 10);
    expect(code.positions[2].offset, 16);
  }

  void test_positions_nonShorthandCaret() {
    final rawCode = '''
String /*0*/a = '^^^';
    ''';
    final expectedCode = '''
String a = '^^^';
    ''';
    final code = TestCode.parse(rawCode, positionShorthand: false);
    expect(code.rawCode, rawCode);
    expect(code.code, expectedCode);

    expect(code.positions, hasLength(1));
    expect(code.position.offset, 7);
    expect(code.position.offset, code.positions[0].offset);

    expect(code.ranges, isEmpty);
  }

  void test_positions_numberReused() {
    final rawCode = '''
/*0*/ /*1*/ /*0*/
''';
    expect(() => TestCode.parse(rawCode), throwsArgumentError);
  }

  void test_positions_shorthand() {
    final rawCode = '''
int ^a = 1
    ''';
    final expectedCode = '''
int a = 1
    ''';
    final code = TestCode.parse(rawCode);
    expect(code.rawCode, rawCode);
    expect(code.code, expectedCode);

    expect(code.positions, hasLength(1));
    expect(code.position.offset, 4);
    expect(code.position.offset, code.positions[0].offset);

    expect(code.ranges, isEmpty);
  }

  void test_positions_shorthandReused() {
    final rawCode = '''
^ ^
''';
    expect(() => TestCode.parse(rawCode), throwsArgumentError);
  }

  void test_positions_shorthandReusedNumber() {
    final rawCode = '''
/*0*/ ^
''';
    expect(() => TestCode.parse(rawCode), throwsArgumentError);
  }

  void test_ranges() {
    final rawCode = '''
int /*[0*/a = 1;/*0]*/
/*[1*/int b = 2;/*1]*/
''';
    final expectedCode = '''
int a = 1;
int b = 2;
''';
    final code = TestCode.parse(rawCode);
    expect(code.rawCode, rawCode);
    expect(code.code, expectedCode);
    expect(code.positions, isEmpty);

    expect(code.ranges, hasLength(2));
    expect(code.ranges[0].sourceRange, SourceRange(4, 6));
    expect(code.ranges[1].sourceRange, SourceRange(11, 10));

    expect(code.ranges[0].text, 'a = 1;');
    expect(code.ranges[1].text, 'int b = 2;');
  }

  void test_ranges_endReused() {
    final rawCode = '''
/*[0*/ /*0]*/
/*[1*/ /*0]*/
''';
    expect(() => TestCode.parse(rawCode), throwsArgumentError);
  }

  void test_ranges_endWithoutStart() {
    final rawCode = '''
/*0]*/
''';
    expect(() => TestCode.parse(rawCode), throwsArgumentError);
  }

  void test_ranges_nonShorthandMarkers() {
    final rawCode = '''
String a = '[!not markers!]';
    ''';
    final code = TestCode.parse(rawCode, rangeShorthand: false);
    expect(code.rawCode, rawCode);
    expect(code.code, rawCode); // No change.

    expect(code.positions, isEmpty);
    expect(code.ranges, isEmpty);
  }

  void test_ranges_shorthand() {
    final rawCode = '''
int [!a = 1;!]
int b = 2;
''';
    final expectedCode = '''
int a = 1;
int b = 2;
''';
    final code = TestCode.parse(rawCode);
    expect(code.rawCode, rawCode);
    expect(code.code, expectedCode);
    expect(code.positions, isEmpty);

    expect(code.ranges, hasLength(1));
    expect(code.ranges[0].sourceRange, SourceRange(4, 6));

    expect(code.ranges[0].text, 'a = 1;');
  }

  void test_ranges_shorthandReused() {
    final rawCode = '''
int [!a = 1;!]
int [!b = 2!];
''';
    expect(() => TestCode.parse(rawCode), throwsArgumentError);
  }

  void test_ranges_shorthandReusedNumber() {
    final rawCode = '''
int [!a = 1;!]
int /*[0*/b = 2/*0]*/;
''';
    expect(() => TestCode.parse(rawCode), throwsArgumentError);
  }

  void test_ranges_startReused() {
    final rawCode = '''
/*[0*/ /*0]*/
/*[0*/ /*1]*/
''';
    expect(() => TestCode.parse(rawCode), throwsArgumentError);
  }

  void test_ranges_startWithoutEnd() {
    final rawCode = '''
/*[0*/
''';
    expect(() => TestCode.parse(rawCode), throwsArgumentError);
  }
}
