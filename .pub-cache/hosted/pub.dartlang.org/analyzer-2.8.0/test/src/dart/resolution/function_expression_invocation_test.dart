// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FunctionExpressionInvocationTest);
    defineReflectiveTests(FunctionExpressionInvocationWithNullSafetyTest);
  });
}

@reflectiveTest
class FunctionExpressionInvocationTest extends PubPackageResolutionTest
    with WithoutNullSafetyMixin {
  test_dynamic_withoutTypeArguments() async {
    await assertNoErrorsInCode(r'''
main() {
  (main as dynamic)(0);
}
''');

    assertFunctionExpressionInvocation(
      findNode.functionExpressionInvocation('(0)'),
      element: null,
      typeArgumentTypes: [],
      invokeType: 'dynamic',
      type: 'dynamic',
    );
  }

  test_dynamic_withTypeArguments() async {
    await assertNoErrorsInCode(r'''
main() {
  (main as dynamic)<bool, int>(0);
}
''');

    assertFunctionExpressionInvocation(
      findNode.functionExpressionInvocation('(0)'),
      element: null,
      typeArgumentTypes: ['bool', 'int'],
      invokeType: 'dynamic',
      type: 'dynamic',
    );
  }
}

@reflectiveTest
class FunctionExpressionInvocationWithNullSafetyTest
    extends PubPackageResolutionTest {
  test_call_infer_fromArguments() async {
    await assertNoErrorsInCode(r'''
class A {
  void call<T>(T t) {}
}

void f(A a) {
  a(0);
}
''');

    assertFunctionExpressionInvocation(
      findNode.functionExpressionInvocation('a(0)'),
      element: findElement.method('call'),
      typeArgumentTypes: ['int'],
      invokeType: 'void Function(int)',
      type: 'void',
    );
  }

  test_call_infer_fromArguments_listLiteral() async {
    await resolveTestCode(r'''
class A {
  List<T> call<T>(List<T> _)  {
    throw 42;
  }
}

main(A a) {
  a([0]);
}
''');

    assertFunctionExpressionInvocation(
      findNode.functionExpressionInvocation('a(['),
      element: findElement.method('call'),
      typeArgumentTypes: ['int'],
      invokeType: 'List<int> Function(List<int>)',
      type: 'List<int>',
    );
  }

  test_call_infer_fromContext() async {
    await assertNoErrorsInCode(r'''
class A {
  T call<T>() {
    throw 42;
  }
}

void f(A a, int context) {
  context = a();
}
''');

    assertFunctionExpressionInvocation(
      findNode.functionExpressionInvocation('a()'),
      element: findElement.method('call'),
      typeArgumentTypes: ['int'],
      invokeType: 'int Function()',
      type: 'int',
    );
  }

  test_call_typeArguments() async {
    await assertNoErrorsInCode(r'''
class A {
  T call<T>() {
    throw 42;
  }
}

void f(A a) {
  a<int>();
}
''');

    assertFunctionExpressionInvocation(
      findNode.functionExpressionInvocation('a<int>()'),
      element: findElement.method('call'),
      typeArgumentTypes: ['int'],
      invokeType: 'int Function()',
      type: 'int',
    );
  }

  test_never() async {
    await assertErrorsInCode(r'''
void f(Never x) {
  x<int>(1 + 2);
}
''', [
      error(HintCode.RECEIVER_OF_TYPE_NEVER, 20, 1),
      error(HintCode.DEAD_CODE, 26, 8),
    ]);

    assertFunctionExpressionInvocation(
      findNode.functionExpressionInvocation('x<int>(1 + 2)'),
      element: null,
      typeArgumentTypes: ['int'],
      invokeType: 'dynamic',
      type: 'Never',
    );

    assertType(findNode.binary('1 + 2'), 'int');
  }

  test_neverQ() async {
    await assertErrorsInCode(r'''
void f(Never? x) {
  x<int>(1 + 2);
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_INVOCATION_OF_NULLABLE_VALUE, 21, 1),
    ]);

    assertFunctionExpressionInvocation(
      findNode.functionExpressionInvocation('x<int>(1 + 2)'),
      element: null,
      typeArgumentTypes: ['int'],
      invokeType: 'dynamic',
      type: 'dynamic',
    );

    assertType(findNode.binary('1 + 2'), 'int');
  }

  test_nullShorting() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  int Function() get foo;
}

class B {
  void bar(A? a) {
    a?.foo();
  }
}
''');

    assertFunctionExpressionInvocation(
      findNode.functionExpressionInvocation('a?.foo()'),
      element: null,
      typeArgumentTypes: [],
      invokeType: 'int Function()',
      type: 'int?',
    );
  }

  test_nullShorting_extends() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  int Function() get foo;
}

class B {
  void bar(A? a) {
    a?.foo().isEven;
  }
}
''');

    assertFunctionExpressionInvocation(
      findNode.functionExpressionInvocation('a?.foo()'),
      element: null,
      typeArgumentTypes: [],
      invokeType: 'int Function()',
      type: 'int',
    );

    assertPropertyAccess2(
      findNode.propertyAccess('isEven'),
      element: intElement.getGetter('isEven'),
      type: 'bool?',
    );
  }
}
