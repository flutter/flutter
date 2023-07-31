// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryWildcardPatternTest);
  });
}

@reflectiveTest
class UnnecessaryWildcardPatternTest extends PubPackageResolutionTest {
  test_forStatement_ForEachPartsWithPattern() async {
    await assertNoErrorsInCode(r'''
void f(List<int> values) {
  for (var (_) in values) {}
}
''');
  }

  test_ifCase_notRequired_logicalAnd_left() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  if (x case _ && 0) {}
}
''', [
      error(WarningCode.UNNECESSARY_WILDCARD_PATTERN, 33, 1),
    ]);
  }

  test_ifCase_notRequired_logicalAnd_right() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  if (x case 0 && _) {}
}
''', [
      error(WarningCode.UNNECESSARY_WILDCARD_PATTERN, 38, 1),
    ]);
  }

  test_ifCase_notRequired_parenthesizedPattern_logicalAnd() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  if (x case (_) && 0) {}
}
''', [
      error(WarningCode.UNNECESSARY_WILDCARD_PATTERN, 34, 1),
    ]);
  }

  test_ifCase_notRequired_typed_promotes() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  if (x case int _ && > 0) {}
}
''');
  }

  test_ifCase_notRequired_typed_sameMatchedType() async {
    await assertErrorsInCode(r'''
void f(int x) {
  if (x case int _ && > 0) {}
}
''', [
      error(WarningCode.UNNECESSARY_WILDCARD_PATTERN, 29, 5),
    ]);
  }

  test_ifCase_required_castPattern() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  if (x case _ as int) {}
}
''');
  }

  test_ifCase_required_listPattern() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  if (x case [_, 0]) {}
}
''');
  }

  test_ifCase_required_logicalOr_left() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  if (x case _ || 0) {}
}
''', [
      error(HintCode.DEAD_CODE, 35, 4),
    ]);
  }

  /// Although this makes the _left_ side useless.
  test_ifCase_required_logicalOr_right() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  if (x case 0 || _) {}
}
''');
  }

  test_ifCase_required_mapPattern() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  if (x case {'foo': _, 'bar': 0}) {}
}
''');
  }

  test_ifCase_required_nullAssert() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  if (x case _!) {}
}
''');
  }

  test_ifCase_required_nullCheck() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  if (x case _?) {}
}
''');
  }

  test_ifCase_required_objectPattern() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  if (x case A(foo: _, bar: _?)) {}
  if (x case A(bar: _?, foo: _)) {}
}

class A {
  int get foo => 0;
  int? get bar => 0;
}
''');
  }

  test_ifCase_required_recordPattern() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  if (x case (_, 0)) {}
}
''');
  }

  test_switchExpression_logicalAnd() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  (switch (x) {
    0 && _ => 0,
  });
}
''', [
      error(WarningCode.UNNECESSARY_WILDCARD_PATTERN, 45, 1),
    ]);
  }

  test_switchExpression_topPattern() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  (switch (x) {
    _ => 0,
  });
}
''');
  }

  test_switchStatement_logicalAnd() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  switch (x) {
    case 0 && _:
      break;
  }
}
''', [
      error(WarningCode.UNNECESSARY_WILDCARD_PATTERN, 49, 1),
    ]);
  }

  test_switchStatement_topPattern() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  switch (x) {
    case _:
      break;
  }
}
''');
  }
}
