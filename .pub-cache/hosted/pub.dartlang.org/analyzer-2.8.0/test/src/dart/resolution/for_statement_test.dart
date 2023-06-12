// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ForEachStatementResolutionTest);
    defineReflectiveTests(ForLoopStatementResolutionTest);
  });
}

/// TODO(scheglov) Move other for-in tests here.
@reflectiveTest
class ForEachStatementResolutionTest extends PubPackageResolutionTest {
  test_forIn_variable() async {
    var code = r'''
T f<T>() => null;

void test(Iterable<num> iter) {
  for (var w in f()) {} // 1
  for (var x in iter) {} // 2
  for (num y in f()) {} // 3
}
''';
    await resolveTestCode(code);

    assertType(findElement.localVar('w').type, 'Object?');
    assertType(findNode.methodInvocation('f()) {} // 1'), 'Iterable<Object?>');

    assertType(findElement.localVar('x').type, 'num');

    assertType(findElement.localVar('y').type, 'num');
    assertType(findNode.methodInvocation('f()) {} // 3'), 'Iterable<num>');
  }

  test_iterable_missing() async {
    await assertErrorsInCode(r'''
void f() {
  for (var v in) {
    v;
  }
}
''', [
      error(ParserErrorCode.MISSING_IDENTIFIER, 26, 1),
    ]);

    assertType(findElement.localVar('v').type, 'dynamic');
    assertType(findNode.simple('v;'), 'dynamic');
  }

  /// Test that the parameter `x` is in the scope of the iterable.
  /// But the declared identifier `x` is in the scope of the body.
  test_scope() async {
    await assertNoErrorsInCode('''
void f(List<List<int>> x) {
  for (int x in x.first) {
    x.isEven;
  }
}
''');

    assertElement(
      findNode.simple('x) {'),
      findElement.parameter('x'),
    );

    assertElement(
      findNode.simple('x.isEven'),
      findElement.localVar('x'),
    );
  }

  test_type_genericFunctionType() async {
    await assertNoErrorsInCode(r'''
void f() {
  for (Null Function<T>(T, Null) e in <dynamic>[]) {
    e;
  }
}
''');
  }

  test_type_inferred() async {
    await assertNoErrorsInCode(r'''
void f(List<int> a) {
  for (var v in a) {
    v;
  }
}
''');

    assertType(findElement.localVar('v').type, 'int');
    assertType(findNode.simple('v;'), 'int');
  }
}

@reflectiveTest
class ForLoopStatementResolutionTest extends PubPackageResolutionTest {
  test_condition_rewrite() async {
    await assertNoErrorsInCode(r'''
f(bool Function() b) {
  for (; b(); ) {
    print(0);
  }
}
''');

    assertFunctionExpressionInvocation(
      findNode.functionExpressionInvocation('b()'),
      element: null,
      typeArgumentTypes: [],
      invokeType: 'bool Function()',
      type: 'bool',
    );
  }
}
