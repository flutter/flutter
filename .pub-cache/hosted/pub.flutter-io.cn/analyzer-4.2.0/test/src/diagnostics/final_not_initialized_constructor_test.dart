// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FinalNotInitializedConstructorTest);
  });
}

@reflectiveTest
class FinalNotInitializedConstructorTest extends PubPackageResolutionTest {
  test_class_1() async {
    await assertErrorsInCode('''
class A {
  final int x;
  A() {}
}
''', [
      error(CompileTimeErrorCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_1, 27, 1),
    ]);
  }

  test_class_2() async {
    await assertErrorsInCode('''
class A {
  final int a;
  final int b;
  A() {}
}
''', [
      error(CompileTimeErrorCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_2, 42, 1),
    ]);
  }

  test_class_3Plus() async {
    await assertErrorsInCode('''
enum E {
  v;
  final int a;
  final int b;
  final int c;
  const E();
}
''', [
      error(
          CompileTimeErrorCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_3_PLUS, 67, 1),
    ]);
  }

  Future<void> test_class_redirecting_error() async {
    await assertErrorsInCode('''
class A {
  final int x;
  A() : this._();
  A._();
}
''', [
      error(CompileTimeErrorCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_1, 45, 1),
    ]);
  }

  Future<void> test_class_redirecting_no_error() async {
    await assertNoErrorsInCode('''
class A {
  final int x;
  A() : this._();
  A._() : x = 0;
}
''');
  }

  Future<void> test_class_two_constructors_no_errors() async {
    await assertNoErrorsInCode('''
class A {
  final int x;
  A.zero() : x = 0;
  A.one() : x = 1;
}
''');
  }

  test_enum_1() async {
    await assertErrorsInCode('''
enum E {
  v;
  final int x;
  const E();
}
''', [
      error(CompileTimeErrorCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_1, 37, 1),
    ]);
  }

  test_enum_2() async {
    await assertErrorsInCode('''
enum E {
  v;
  final int a;
  final int b;
  const E();
}
''', [
      error(CompileTimeErrorCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_2, 52, 1),
    ]);
  }

  Future<void> test_enum_redirecting_error() async {
    await assertErrorsInCode('''
enum E {
  v1, v2._();
  final int x;
  const E() : this._();
  const E._();
}
''', [
      error(CompileTimeErrorCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_1, 70, 1),
    ]);
  }

  Future<void> test_enum_redirecting_no_error() async {
    await assertNoErrorsInCode('''
enum E {
  v1, v2._();
  final int x;
  const E() : this._();
  const E._() : x = 0;
}
''');
  }

  Future<void> test_enum_two_constructors_no_errors() async {
    await assertNoErrorsInCode('''
enum E {
  v1.zero(), v2.one();
  final int x;
  const E.zero() : x = 0;
  const E.one() : x = 1;
}
''');
  }
}
