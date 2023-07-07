// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MissingReturnTest);
    defineReflectiveTests(MissingReturnWithoutNullSafetyTest);
  });
}

@reflectiveTest
class MissingReturnTest extends PubPackageResolutionTest {
  test_function_async_block_futureOrVoid() async {
    await assertNoErrorsInCode('''
import 'dart:async';
FutureOr<void> f() async {}
''');
  }

  test_function_async_block_void() async {
    await assertNoErrorsInCode('''
void f() async {}
''');
  }

  test_function_sync_block_dynamic() async {
    await assertNoErrorsInCode('''
dynamic f() {}
''');
  }

  test_function_sync_block_Never() async {
    newFile('$testPackageLibPath/a.dart', r'''
Never foo() {
  throw 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.8
import 'a.dart';

int f() {
  foo();
}
''');
  }

  test_function_sync_block_Null() async {
    await assertNoErrorsInCode('''
Null f() {}
''');
  }

  test_function_sync_block_void() async {
    await assertNoErrorsInCode('''
void f() {}
''');
  }
}

@reflectiveTest
class MissingReturnWithoutNullSafetyTest extends PubPackageResolutionTest
    with WithoutNullSafetyMixin {
  test_alwaysThrows() async {
    writeTestPackageConfigWithMeta();
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

@alwaysThrows
void a() {
  throw 'msg';
}

int f() {
  a();
}''');
  }

  test_constructor_factory() async {
    await assertErrorsInCode(r'''
class A {
  factory A() {}
}
''', [
      error(HintCode.MISSING_RETURN, 12, 14),
    ]);
  }

  test_function_async_block_futureInt() async {
    await assertErrorsInCode(r'''
Future<int> f() async {}
''', [
      error(HintCode.MISSING_RETURN, 12, 1),
    ]);
  }

  test_function_async_block_futureOrVoid() async {
    await assertNoErrorsInCode(r'''
import 'dart:async';
FutureOr<void> f(Future f) async {}
''');
  }

  test_function_async_block_futureVoid() async {
    await assertNoErrorsInCode(r'''
Future<void> f() async {}
''');
  }

  test_function_sync_block_expression() async {
    await assertNoErrorsInCode(r'''
int f() => 0;
''');
  }

  test_function_sync_block_int() async {
    await assertErrorsInCode(r'''
int f() {}
''', [
      error(HintCode.MISSING_RETURN, 4, 1),
    ]);
  }

  test_function_sync_block_noReturnType() async {
    await assertNoErrorsInCode(r'''
f() {}
''');
  }

  test_function_sync_block_void() async {
    await assertNoErrorsInCode(r'''
void f() {}
''');
  }

  test_functionExpression_async_block_dynamic() async {
    await assertNoErrorsInCode(r'''
Future Function() f = () async {};
''');
  }

  test_functionExpression_async_block_futureInt() async {
    await assertErrorsInCode(r'''
Future<int> Function() f = () async {};
''', [
      error(HintCode.MISSING_RETURN, 27, 11),
    ]);
  }

  test_functionExpression_async_block_void() async {
    await assertNoErrorsInCode(r'''
void Function(bool) v = (bool a) async {
  if (a) {
    return 0;
  }
};
''');
  }

  test_functionExpression_sync_block_futureOrDynamic() async {
    await assertNoErrorsInCode(r'''
import 'dart:async';

FutureOr<dynamic> Function() f = () {};
''');
  }

  test_functionExpression_sync_block_futureOrInt() async {
    await assertErrorsInCode(r'''
import 'dart:async';

FutureOr<int> Function() f = () {};
''', [
      error(HintCode.MISSING_RETURN, 51, 5),
    ]);
  }

  test_functionExpression_sync_block_int() async {
    await assertErrorsInCode(r'''
int Function() f = () {};
''', [
      error(HintCode.MISSING_RETURN, 19, 5),
    ]);
  }

  test_functionExpression_sync_dynamic() async {
    await assertNoErrorsInCode('''
Function() f = () {};
''');
  }

  test_functionExpression_sync_expression() async {
    await assertNoErrorsInCode(r'''
int Function() f = () => null;
''');
  }

  test_localFunction_sync_dynamic() async {
    await assertNoErrorsInCode(r'''
void foo() {
  f() {}
  f;
}
''');
  }

  test_method_emptyFunctionBody() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  int m();
}
''');
  }

  test_method_sync_block_futureOrDynamic() async {
    await assertNoErrorsInCode(r'''
import 'dart:async';

class A {
  FutureOr<dynamic> m() {}
}
''');
  }

  test_method_sync_block_futureOrInt() async {
    await assertErrorsInCode(r'''
import 'dart:async';

class A {
  FutureOr<int> m() {}
}
''', [
      error(HintCode.MISSING_RETURN, 48, 1),
    ]);
  }

  test_method_sync_block_int() async {
    await assertErrorsInCode(r'''
class A {
  int m() {}
}
''', [
      error(HintCode.MISSING_RETURN, 16, 1),
    ]);
  }

  test_method_sync_block_int_inferred() async {
    await assertErrorsInCode(r'''
abstract class A {
  int m();
}

class B extends A {
  m() {}
}
''', [
      error(HintCode.MISSING_RETURN, 55, 1),
    ]);
  }
}
