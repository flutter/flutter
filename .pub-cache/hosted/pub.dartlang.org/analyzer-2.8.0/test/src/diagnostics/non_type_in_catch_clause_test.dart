// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonTypeInCatchClauseTest);
  });
}

@reflectiveTest
class NonTypeInCatchClauseTest extends PubPackageResolutionTest {
  test_isClass() async {
    await assertNoErrorsInCode(r'''
f() {
  try {
  } on String catch (e) {
    e;
  }
}
''');
  }

  test_isFunctionTypeAlias() async {
    await assertNoErrorsInCode(r'''
typedef F();
f() {
  try {
  } on F catch (e) {
    e;
  }
}
''');
  }

  test_isGenericFunctionTypeAlias() async {
    await assertNoErrorsInCode(r'''
typedef F<T> = void Function(T);
f() {
  try {
  } on F catch (e) {
    e;
  }
}
''');
  }

  test_isInterfaceTypeTypeAlias() async {
    await assertNoErrorsInCode(r'''
typedef F = String;
f() {
  try {
  } on F catch (e) {
    e;
  }
}
''');
  }

  test_isTypeParameter() async {
    await assertNoErrorsInCode(r'''
class A<T extends Object> {
  f() {
    try {
    } on T catch (e) {
      e;
    }
  }
}
''');
  }

  test_notDefined() async {
    await assertErrorsInCode('''
f() {
  try {
  } on T catch (e) {
    e;
  }
}
''', [
      // TODO(srawlins): Ideally the first error should not be reported.
      error(HintCode.NULLABLE_TYPE_IN_CATCH_CLAUSE, 21, 1),
      error(CompileTimeErrorCode.NON_TYPE_IN_CATCH_CLAUSE, 21, 1),
    ]);
  }

  test_notType() async {
    await assertErrorsInCode('''
var T = 0;
f() {
  try {
  } on T catch (e) {
    e;
  }
}
''', [
      // TODO(srawlins): Ideally the first error should not be reported.
      error(HintCode.NULLABLE_TYPE_IN_CATCH_CLAUSE, 32, 1),
      error(CompileTimeErrorCode.NON_TYPE_IN_CATCH_CLAUSE, 32, 1),
    ]);
  }

  test_noType() async {
    await assertNoErrorsInCode(r'''
f() {
  try {
  } catch (e) {
  }
}
''');
  }
}
