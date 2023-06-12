// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonConstantMapElementTest);
    defineReflectiveTests(NonConstantMapKeyTest);
    defineReflectiveTests(NonConstantMapValueTest);
  });
}

@reflectiveTest
class NonConstantMapElementTest extends PubPackageResolutionTest
    with NonConstantMapElementTestCases {}

mixin NonConstantMapElementTestCases on PubPackageResolutionTest {
  test_forElement_cannotBeConst() async {
    await assertErrorsInCode('''
void main() {
  const {1: null, for (final x in const []) null: null};
}
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT, 32, 36),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 43, 1),
    ]);
  }

  test_forElement_nested_cannotBeConst() async {
    await assertErrorsInCode('''
void main() {
  const {1: null, if (true) for (final x in const []) null: null};
}
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT, 42, 36),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 53, 1),
    ]);
  }

  test_forElement_notConst_noError() async {
    await assertNoErrorsInCode('''
void main() {
  var x;
  print({x: x, for (final x2 in [x]) x2: x2});
}
''');
  }

  test_ifElement_mayBeConst() async {
    await assertNoErrorsInCode('''
void main() {
  const {1: null, if (true) null: null};
}
''');
  }

  test_ifElement_nested_mayBeConst() async {
    await assertNoErrorsInCode('''
void main() {
  const {1: null, if (true) if (true) null: null};
}
''');
  }

  test_ifElement_notConstCondition() async {
    await assertErrorsInCode('''
void main() {
  bool notConst = true;
  const {1: null, if (notConst) null: null};
}
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT, 60, 8),
    ]);
  }

  test_ifElementWithElse_mayBeConst() async {
    await assertErrorsInCode('''
void main() {
  const isTrue = true;
  const {1: null, if (isTrue) null: null else null: null};
}
''', [
      error(HintCode.DEAD_CODE, 83, 10),
    ]);
  }

  test_spreadElement_mayBeConst() async {
    await assertNoErrorsInCode('''
void main() {
  const {1: null, ...{null: null}};
}
''');
  }

  test_spreadElement_notConst() async {
    await assertErrorsInCode('''
void main() {
  var notConst = {};
  const {1: null, ...notConst};
}
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT, 56, 8),
    ]);
  }
}

@reflectiveTest
class NonConstantMapKeyTest extends PubPackageResolutionTest
    with NonConstantMapKeyTestCases {}

@reflectiveTest
mixin NonConstantMapKeyTestCases on PubPackageResolutionTest {
  test_const_ifElement_thenElseFalse_finalElse() async {
    await assertErrorsInCode('''
final dynamic a = 0;
var v = const <int, int>{if (1 < 0) 0: 0 else a: 0};
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_MAP_KEY, 67, 1),
    ]);
  }

  test_const_ifElement_thenElseFalse_finalThen() async {
    await assertErrorsInCode('''
final dynamic a = 0;
var v = const <int, int>{if (1 < 0) a: 0 else 0: 0};
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_MAP_KEY, 57, 1),
    ]);
  }

  test_const_ifElement_thenElseTrue_finalElse() async {
    await assertErrorsInCode('''
final dynamic a = 0;
var v = const <int, int>{if (1 > 0) 0: 0 else a: 0};
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_MAP_KEY, 67, 1),
    ]);
  }

  test_const_ifElement_thenElseTrue_finalThen() async {
    await assertErrorsInCode('''
final dynamic a = 0;
var v = const <int, int>{if (1 > 0) a: 0 else 0: 0};
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_MAP_KEY, 57, 1),
    ]);
  }

  test_const_ifElement_thenFalse_constThen() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
var v = const <int, int>{if (1 < 0) a: 0};
''');
  }

  test_const_ifElement_thenFalse_finalThen() async {
    await assertErrorsInCode('''
final dynamic a = 0;
var v = const <int, int>{if (1 < 0) a: 0};
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_MAP_KEY, 57, 1),
    ]);
  }

  test_const_ifElement_thenTrue_constThen() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
var v = const <int, int>{if (1 > 0) a: 0};
''');
  }

  test_const_ifElement_thenTrue_finalThen() async {
    await assertErrorsInCode('''
final dynamic a = 0;
var v = const <int, int>{if (1 > 0) a: 0};
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_MAP_KEY, 57, 1),
    ]);
  }

  test_const_topVar() async {
    await assertErrorsInCode('''
final dynamic a = 0;
var v = const <int, int>{a: 0};
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_MAP_KEY, 46, 1),
    ]);
  }

  test_nonConst_topVar() async {
    await assertNoErrorsInCode('''
final dynamic a = 0;
var v = <int, int>{a: 0};
''');
  }
}

@reflectiveTest
class NonConstantMapValueTest extends PubPackageResolutionTest
    with NonConstantMapValueTestCases {}

mixin NonConstantMapValueTestCases on PubPackageResolutionTest {
  test_const_ifElement_thenElseFalse_finalElse() async {
    await assertErrorsInCode('''
final dynamic a = 0;
var v = const <int, int>{if (1 < 0) 0: 0 else 0: a};
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE, 70, 1),
    ]);
  }

  test_const_ifElement_thenElseFalse_finalThen() async {
    await assertErrorsInCode('''
final dynamic a = 0;
var v = const <int, int>{if (1 < 0) 0: a else 0: 0};
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE, 60, 1),
    ]);
  }

  test_const_ifElement_thenElseTrue_finalElse() async {
    await assertErrorsInCode('''
final dynamic a = 0;
var v = const <int, int>{if (1 > 0) 0: 0 else 0: a};
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE, 70, 1),
    ]);
  }

  test_const_ifElement_thenElseTrue_finalThen() async {
    await assertErrorsInCode('''
final dynamic a = 0;
var v = const <int, int>{if (1 > 0) 0: a else 0: 0};
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE, 60, 1),
    ]);
  }

  test_const_ifElement_thenFalse_constThen() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
var v = const <int, int>{if (1 < 0) 0: a};
''');
  }

  test_const_ifElement_thenFalse_finalThen() async {
    await assertErrorsInCode('''
final dynamic a = 0;
var v = const <int, int>{if (1 < 0) 0: a};
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE, 60, 1),
    ]);
  }

  test_const_ifElement_thenTrue_constThen() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
var v = const <int, int>{if (1 > 0) 0: a};
''');
  }

  test_const_ifElement_thenTrue_finalThen() async {
    await assertErrorsInCode('''
final dynamic a = 0;
var v = const <int, int>{if (1 > 0) 0: a};
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE, 60, 1),
    ]);
  }

  test_const_topVar() async {
    await assertErrorsInCode('''
final dynamic a = 0;
var v = const <int, int>{0: a};
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE, 49, 1),
    ]);
  }

  test_nonConst_topVar() async {
    await assertNoErrorsInCode('''
final dynamic a = 0;
var v = <int, int>{0: a};
''');
  }
}
