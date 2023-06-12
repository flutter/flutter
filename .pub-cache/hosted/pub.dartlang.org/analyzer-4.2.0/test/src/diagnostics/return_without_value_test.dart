// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReturnWithoutValueTest);
    defineReflectiveTests(ReturnWithoutValueWithoutNullSafetyTest);
  });
}

@reflectiveTest
class ReturnWithoutValueTest extends PubPackageResolutionTest
    with ReturnWithoutValueTestCases {}

mixin ReturnWithoutValueTestCases on PubPackageResolutionTest {
  test_async_futureInt() async {
    await assertErrorsInCode('''
Future<int> f() async {
  return;
}
''', [
      error(CompileTimeErrorCode.RETURN_WITHOUT_VALUE, 26, 6),
    ]);
  }

  test_async_futureObject() async {
    await assertErrorsInCode('''
Future<Object> f() async {
  return;
}
''', [
      error(CompileTimeErrorCode.RETURN_WITHOUT_VALUE, 29, 6),
    ]);
  }

  test_catchError_futureOfVoid() async {
    await assertNoErrorsInCode('''
void f(Future<void> future) {
  future.catchError((e) {
    return;
  });
}
''');
  }

  test_factoryConstructor() async {
    await assertErrorsInCode('''
class A {
  factory A() {
    return;
  }
}
''', [
      error(CompileTimeErrorCode.RETURN_WITHOUT_VALUE, 30, 6),
    ]);
  }

  test_function() async {
    await assertErrorsInCode('''
int f() {
  return;
}
''', [
      error(CompileTimeErrorCode.RETURN_WITHOUT_VALUE, 12, 6),
    ]);
  }

  test_function_async_block_empty__to_dynamic() async {
    await assertNoErrorsInCode('''
dynamic f() async {
  return;
}
''');
  }

  test_function_Null() async {
    // Test that block bodied functions with return type Null and an empty
    // return cause a static warning.
    await assertNoErrorsInCode('''
Null f() {
  return;
}
''');
  }

  test_function_sync_block_empty__to_dynamic() async {
    await assertNoErrorsInCode('''
dynamic f() {
  return;
}
''');
  }

  test_function_sync_block_empty__to_Null() async {
    await assertNoErrorsInCode('''
Null f() {
  return;
}
''');
  }

  test_function_void() async {
    await assertNoErrorsInCode('''
void f() {
  return;
}
''');
  }

  test_functionExpression() async {
    await assertErrorsInCode('''
f() {
  return (int y) {
    if (y < 0) {
      return;
    }
    return 0;
  };
}
''', [
      error(CompileTimeErrorCode.RETURN_WITHOUT_VALUE, 48, 6),
    ]);
  }

  test_functionExpression_async_block_empty__to_Object() async {
    await assertNoErrorsInCode('''
Object Function() f = () async {
  return;
};
''');
  }

  test_method() async {
    await assertErrorsInCode('''
class A {
  int m() {
    return;
  }
}
''', [
      error(CompileTimeErrorCode.RETURN_WITHOUT_VALUE, 26, 6),
    ]);
  }

  test_multipleInconsistentReturns() async {
    // Tests that only the RETURN_WITHOUT_VALUE warning is created, and no
    // MIXED_RETURN_TYPES are created.
    await assertErrorsInCode('''
int f(int x) {
  if (x < 0) {
    return 1;
  }
  return;
}
''', [
      error(CompileTimeErrorCode.RETURN_WITHOUT_VALUE, 50, 6),
    ]);
  }
}

@reflectiveTest
class ReturnWithoutValueWithoutNullSafetyTest extends PubPackageResolutionTest
    with ReturnWithoutValueTestCases, WithoutNullSafetyMixin {}
