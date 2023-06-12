// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NullableTypeInCatchClauseTest);
  });
}

@reflectiveTest
class NullableTypeInCatchClauseTest extends PubPackageResolutionTest {
  test_noOnClause() async {
    await assertNoErrorsInCode('''
f() {
  try {
  } catch (e) {
  }
}
''');
  }

  test_on_dynamic() async {
    await assertErrorsInCode('''
class A {}
f() {
  try {
  } on dynamic {
  }
}
''', [
      error(HintCode.NULLABLE_TYPE_IN_CATCH_CLAUSE, 32, 7),
    ]);
  }

  test_on_functionType_nonNullable() async {
    await assertNoErrorsInCode('''
f() {
  try {
  } on void Function() {
  }
}
''');
  }

  test_on_functionType_nullable() async {
    await assertErrorsInCode('''
f() {
  try {
  } on void Function()? {
  }
}
''', [
      error(HintCode.NULLABLE_TYPE_IN_CATCH_CLAUSE, 21, 16),
    ]);
  }

  test_on_interfaceType_nonNullable() async {
    await assertNoErrorsInCode('''
f() {
  try {
  } on int {
  }
}
''');
  }

  test_on_interfaceType_nullable() async {
    await assertErrorsInCode('''
f() {
  try {
  } on int? {
  }
}
''', [
      error(HintCode.NULLABLE_TYPE_IN_CATCH_CLAUSE, 21, 4),
    ]);
  }

  test_on_typeParameter_nonNullable() async {
    await assertNoErrorsInCode('''
class A<B extends Object> {
  m() {
    try {
    } on B {
    }
  }
}
''');
  }

  test_on_typeParameter_nullable() async {
    await assertErrorsInCode('''
class A<B> {
  m() {
    try {
    } on B {
    }
  }
}
''', [
      error(HintCode.NULLABLE_TYPE_IN_CATCH_CLAUSE, 40, 1),
    ]);
  }

  test_optOut() async {
    await assertNoErrorsInCode('''
// @dart = 2.7

void f() {
  try {
  } on dynamic {
  }
}
''');
  }
}
