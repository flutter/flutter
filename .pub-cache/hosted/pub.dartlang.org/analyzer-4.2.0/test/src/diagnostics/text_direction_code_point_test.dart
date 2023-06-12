// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnsafeTextDirectionCodepointTest);
  });
}

@reflectiveTest
class UnsafeTextDirectionCodepointTest extends PubPackageResolutionTest {
  test_comments() async {
    await assertErrorsInCode('''
// \u2066
/// \u2066
void f() { // \u2066
  // \u2066
}
''', [
      error(HintCode.TEXT_DIRECTION_CODE_POINT_IN_COMMENT, 3, 1),
      error(HintCode.TEXT_DIRECTION_CODE_POINT_IN_COMMENT, 9, 1),
      error(HintCode.TEXT_DIRECTION_CODE_POINT_IN_COMMENT, 25, 1),
      error(HintCode.TEXT_DIRECTION_CODE_POINT_IN_COMMENT, 32, 1),
    ]);
  }

  /// https://github.com/flutter/flutter/pull/93029
  test_file_ok() async {
    // Raw strings preserve the escapes.
    await assertNoErrorsInCode(r'''
var u202a = '\u202AInteractive text\u202C';
''');
  }

  test_message_escape() async {
    await assertErrorsInCode('''
var u202a = '\u202A';
''', [
      error(HintCode.TEXT_DIRECTION_CODE_POINT_IN_LITERAL, 13, 1,
          messageContains: ['U+202A']),
    ]);
  }

  test_multiLineString() async {
    await assertErrorsInCode('''
var s = """ \u202a
        Multiline!
""";
''', [
      error(HintCode.TEXT_DIRECTION_CODE_POINT_IN_LITERAL, 12, 1),
    ]);
  }

  test_simpleStrings() async {
    await assertErrorsInCode('''
var u202a = '\u202A';
var u202b = '\u202B';
var u202c = '\u202C';
var u202d = '\u202D';
var u202e = '\u202E';
var u2066 = '\u2066';
var u2067 = '\u2067';
var u2068 = '\u2068';
var u2069 = '\u2069';
''', [
      error(HintCode.TEXT_DIRECTION_CODE_POINT_IN_LITERAL, 13, 1),
      error(HintCode.TEXT_DIRECTION_CODE_POINT_IN_LITERAL, 30, 1),
      error(HintCode.TEXT_DIRECTION_CODE_POINT_IN_LITERAL, 47, 1),
      error(HintCode.TEXT_DIRECTION_CODE_POINT_IN_LITERAL, 64, 1),
      error(HintCode.TEXT_DIRECTION_CODE_POINT_IN_LITERAL, 81, 1),
      error(HintCode.TEXT_DIRECTION_CODE_POINT_IN_LITERAL, 98, 1),
      error(HintCode.TEXT_DIRECTION_CODE_POINT_IN_LITERAL, 115, 1),
      error(HintCode.TEXT_DIRECTION_CODE_POINT_IN_LITERAL, 132, 1),
      error(HintCode.TEXT_DIRECTION_CODE_POINT_IN_LITERAL, 149, 1),
    ]);
  }

  test_stringInterpolation() async {
    await assertErrorsInCode('''
var x = 'x';
var u202a = '\u202A\$x';
''', [
      error(HintCode.TEXT_DIRECTION_CODE_POINT_IN_LITERAL, 26, 1),
    ]);
  }
}
