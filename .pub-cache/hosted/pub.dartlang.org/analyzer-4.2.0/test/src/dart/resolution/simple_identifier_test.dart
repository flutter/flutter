// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SimpleIdentifierResolutionTest);
    defineReflectiveTests(SimpleIdentifierResolutionWithoutNullSafetyTest);
  });
}

@reflectiveTest
class SimpleIdentifierResolutionTest extends PubPackageResolutionTest
    with SimpleIdentifierResolutionTestCases {
  test_enum_typeParameter_in_method() async {
    await assertNoErrorsInCode('''
enum E<T> {
  v;
  void foo() {
    T;
  }
}
''');

    assertSimpleIdentifier(
      findNode.simple('T;'),
      element: findElement.typeParameter('T'),
      type: 'Type',
    );
  }

  test_functionReference() async {
    await assertErrorsInCode('''
// @dart = 2.7
import 'dart:math';

class A {
  const A(_);
}

@A([min])
main() {}
''', [
      error(CompileTimeErrorCode.COULD_NOT_INFER, 66, 5),
    ]);

    var identifier = findNode.simple('min]');
    assertElement(
      identifier,
      elementMatcher(
        findElement.importFind('dart:math').topFunction('min'),
        isLegacy: true,
      ),
    );
    assertType(identifier, 'T* Function<T extends num*>(T*, T*)*');
  }

  test_implicitCall_tearOff_nullable() async {
    await assertErrorsInCode('''
class A {
  int call() => 0;
}

int Function() foo(A? a) {
  return a;
}
''', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 68, 1),
    ]);

    var identifier = findNode.simple('a;');
    assertElement(identifier, findElement.parameter('a'));
    assertType(identifier, 'A?');
  }
}

mixin SimpleIdentifierResolutionTestCases on PubPackageResolutionTest {
  test_dynamic_explicitCore() async {
    await assertNoErrorsInCode(r'''
import 'dart:core';

main() {
  dynamic;
}
''');

    assertSimpleIdentifier(
      findNode.simple('dynamic;'),
      element: dynamicElement,
      type: 'Type',
    );
  }

  test_dynamic_explicitCore_withPrefix_referenceWithout() async {
    await assertErrorsInCode(r'''
import 'dart:core' as mycore;

main() {
  dynamic;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 42, 7),
    ]);

    assertSimpleIdentifier(
      findNode.simple('dynamic;'),
      element: null,
      type: 'dynamic',
    );
  }

  test_dynamic_implicitCore() async {
    await assertNoErrorsInCode(r'''
main() {
  dynamic;
}
''');

    assertSimpleIdentifier(
      findNode.simple('dynamic;'),
      element: dynamicElement,
      type: 'Type',
    );
  }

  test_implicitCall_tearOff() async {
    await assertNoErrorsInCode('''
class A {
  int call() => 0;
}

int Function() foo(A a) {
  return a;
}
''');

    var identifier = findNode.simple('a;');
    assertElement(identifier, findElement.parameter('a'));
    assertType(identifier, 'A');
  }

  test_localFunction_generic() async {
    await assertNoErrorsInCode('''
class C<T> {
  static void foo<S>(S s) {
    void f<U>(S s, U u) {}
    f;
  }
}
''');

    var identifier = findNode.simple('f;');
    assertElement(identifier, findElement.localFunction('f'));
    assertType(identifier, 'void Function<U>(S, U)');
  }

  test_never_implicitCore() async {
    await assertNoErrorsInCode(r'''
main() {
  Never;
}
''');
    assertSimpleIdentifier(
      findNode.simple('Never;'),
      element: neverElement,
      type: 'Type',
    );
  }

  test_tearOff_function_topLevel() async {
    await assertNoErrorsInCode('''
void foo(int a) {}

main() {
  foo;
}
''');

    var identifier = findNode.simple('foo;');
    assertElement(identifier, findElement.topFunction('foo'));
    assertType(identifier, 'void Function(int)');
  }

  test_tearOff_method() async {
    await assertNoErrorsInCode('''
class A {
  void foo(int a) {}

  bar() {
    foo;
  }
}
''');

    var identifier = findNode.simple('foo;');
    assertElement(identifier, findElement.method('foo'));
    assertType(identifier, 'void Function(int)');
  }
}

@reflectiveTest
class SimpleIdentifierResolutionWithoutNullSafetyTest
    extends PubPackageResolutionTest
    with SimpleIdentifierResolutionTestCases, WithoutNullSafetyMixin {}
